//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Nipuna Weerapperuma on 7/25/23.
//

import Foundation

struct EmojiArtModel {
    var background = Background.blank
    var emojis = [Emoji]()
    private var uniqueEmojiID = 0
    
    
    init() {} // Empty initializer so nobody can attempt to initialize emojis
    
    mutating func addEmoji(_  text: String, at location: (x: Int, y: Int), size: Int) {
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, isRemoved: false, id: uniqueEmojiID))
        uniqueEmojiID += 1
    }
    
    mutating func removeEmoji(with id: Int) {
        emojis[id].isRemoved = true
    }
    
    struct Emoji: Identifiable, Hashable {
        let text: String
        var x: Int // offset from center
        var y: Int // offset from center
        var size: Int
        var isRemoved: Bool
        let id: Int
        
        fileprivate init(text: String, x: Int, y: Int, size: Int, isRemoved: Bool, id: Int) { //Anyone in this file can use this, but nobody else (only we can create emojis)
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
            self.isRemoved = isRemoved
        }
    }
    
}
