//
//  Object.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/23/25.
//

import FirebaseFirestore
import FirebaseStorage
import SwiftUI

struct Object: Codable, Hashable, Identifiable {
    @DocumentID var id: String?
    
    var name: String
    var imagePath: String
    var downloadUrl: URL
    var wins: [DocumentReference]
    var loses: [DocumentReference]
    var winCount: Int
    var timesUsed: Int
    
    static var placeholder: Object = Object(
        name: "Rock",
        imagePath: "images/6834D814-5711-415F-99CD-4B6A0F698F1F.jpg",
        downloadUrl: URL(string: "https://banner2.cleanpng.com/20180417/xve/avfo64zl4.webp")!,
        wins: [],
        loses: [],
        winCount: 5,
        timesUsed: 8)
    
    static func object(named name: String) -> Object {
        var object = Object.placeholder
        object.name = name
        return object
    }
    
    mutating func update(with newObject: Object) {
        name = newObject.name
        imagePath = newObject.imagePath
        wins = newObject.wins
        loses = newObject.loses
        winCount = newObject.winCount
        timesUsed = newObject.timesUsed
    }
}
