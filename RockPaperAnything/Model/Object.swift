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
    var wins: [DocumentReference]
    var loses: [DocumentReference]
    var winCount: Int
    var timesUsed: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imagePath
        case wins
        case loses
        case winCount
        case timesUsed
    }
    
    static var placeholder: Object = Object(
        name: "Rock",
        imagePath: "images/6834D814-5711-415F-99CD-4B6A0F698F1F.jpg",
        wins: [],
        loses: [],
        winCount: 5,
        timesUsed: 8)
    
    mutating func update(with newObject: Object) {
        name = newObject.name
        imagePath = newObject.imagePath
        wins = newObject.wins
        loses = newObject.loses
        winCount = newObject.winCount
        timesUsed = newObject.timesUsed
    }
    
    func getImageUrl() async -> URL? {
        let storage = Storage.storage()
        let storageRef = storage.reference(withPath: imagePath)
        
        do {
            return try await storageRef.downloadURL()
        } catch {
            print("Error getting URL: \(error)")
            return nil
        }
    }
}
