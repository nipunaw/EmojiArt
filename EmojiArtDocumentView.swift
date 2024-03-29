//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Nipuna Weerapperuma on 7/25/23.
//

import SwiftUI

struct EmojiArtDocumentView: View {

    @ObservedObject var document: EmojiArtDocument
    let defaultEmojiFontSize: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
            deleteEmojiButton
        }
    }

    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0,0), in: geometry))
                )
                .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: tapToDeselect()))
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        if !emoji.isRemoved {
                            Text(emoji.text)
                                .font(.system(size: fontSize(for: emoji)))
                                .border(.gray, width: (selectedEmojiIDs.contains(emoji.id) ? 1 : 0))
                                .scaleEffect(calculateEmojiScale(for: emoji) * zoomScale)
                                .position(position(for: emoji, in: geometry))
                                .gesture(tapToToggleSelect(for: emoji).simultaneously(with: dragEmojiGesture(for: emoji)))
                        }
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText,.url,.image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
        }
    }

    var palette: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    var deleteEmojiButton: some View {
        Button("Delete Selected Emojis") {
            for id in selectedEmojiIDs {
                document.removeEmoji(with: id)
                selectedEmojiIDs.remove(id)
            }
        }.disabled(selectedEmojiIDs.isEmpty)
    }


    // MARK: - Drag and Drop
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(.url(url.imageURL))
        }
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data))
                }
            }
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale
                    )
                }
            }
        }
        return found
    }

    // MARK: - Positioning/Sizing Emoji
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        var x: Int
        var y: Int
        if selectedEmojiIDs.contains(emoji.id) {
            x = emoji.x + Int(emojiGestureDragOffset.width)
            y = emoji.y + Int(emojiGestureDragOffset.height)
        } else {
            x = emoji.x
            y = emoji.y
        }
        return convertFromEmojiCoordinates((x, y), in: geometry)
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    // MARK: - Zooming
    
    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * (selectedEmojiIDs.isEmpty ? gestureZoomScale : 1)
    }
    
    private func calculateEmojiScale(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        if selectedEmojiIDs.contains(emoji.id) {
            return gestureZoomScale
        }
        return CGFloat(1)
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScaleAtEnd in
                if selectedEmojiIDs.isEmpty {
                    steadyStateZoomScale *= gestureScaleAtEnd
                } else {
                    for emoji in document.emojis {
                        if selectedEmojiIDs.contains(emoji.id) {
                            document.scaleEmoji(emoji, by: gestureScaleAtEnd)
                        }
                    }
                }
                
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0  {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    // MARK: - Panning
    
    @State private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    @GestureState private var emojiGestureDragOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private var isEmojiDragging: Bool {
        emojiGestureDragOffset != CGSize.zero
    }
    
    private func panGesture() -> some Gesture { // Only triggers if you're dragging in document area
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    private func dragEmojiGesture(for emoji: EmojiArtModel.Emoji) -> some Gesture { // Only triggers if you're dragging on top of emoji
        if selectedEmojiIDs.contains(emoji.id) { // Check if you're dragging on top of a selected emoji
            return DragGesture()
                .updating($emojiGestureDragOffset) { latestDragGestureValue, emojiGestureDragOffset, _ in
                    emojiGestureDragOffset = latestDragGestureValue.translation / zoomScale
                }
                .onEnded { finalDragGestureValue in
                    for e in document.emojis {
                        if selectedEmojiIDs.contains(e.id) {
                            document.moveEmoji(e, by: (finalDragGestureValue.translation / zoomScale))
                        }
                    }
                }
        } else { // Adds support to pan around if you're dragging on top of a un-selected emoji (this is repeated code from panGesture() that ideally can be re-factored)
            return DragGesture()
                .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                    gesturePanOffset = latestDragGestureValue.translation / zoomScale
                }
                .onEnded { finalDragGestureValue in
                    steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
                }
        }
    }

    // MARK: - Selection/Deselection

    @State private var selectedEmojiIDs = Set<Int>()

    private func tapToToggleSelect(for emoji: EmojiArtModel.Emoji) -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                if selectedEmojiIDs.remove(emoji.id) == nil {
                    selectedEmojiIDs.insert(emoji.id)
                }
            }
    }

    private func tapToDeselect() -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                selectedEmojiIDs = Set<Int>()
            }
    }

    let testEmojis = "😀😷🦠💉👻👀🐶🌲🌎🌞🔥🍎⚽️🚗🚓🚲🛩🚁🚀🛸🏠⌚️🎁🗝🔐❤️⛔️❌❓✅⚠️🎶➕➖🏳️"
}

struct ScrollingEmojisView: View {
    let emojis: String
    
    var body: some View {

        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0)}, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }

    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
