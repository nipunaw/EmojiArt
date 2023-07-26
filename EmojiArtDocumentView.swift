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
        }
    }

    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.yellow
                ForEach(document.emojis) { emoji in
                    Text(emoji)
                        .font(.system(size: fontSize(for: emoji)))
                        .position(position(for: emoji, in: geometry))
                }
            }
            .onDrop(of: [.plainText], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
        }
    }

    var palette: some View {
        ScrollingEmojisView(emojis: testemojis)
            .font(.system(size: defaultEmojiFontSize))
    }


    // MARK: - Drag and Drop
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        return providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize // / zoomScale
                    )
                }
        }
    }

    // MARK: - Positioning/Sizing Emoji
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - center.x), //  - panOffset.width / zoomScale
            y: (location.y - center.y) //  - panOffset.height / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x), // * zoomScale + panOffset.width
            y: center.y + CGFloat(location.y) // * zoomScale + panOffset.height
        )
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
