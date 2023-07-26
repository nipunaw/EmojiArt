//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Nipuna Weerapperuma on 7/25/23.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
