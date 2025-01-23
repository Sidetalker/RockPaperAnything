//
//  ObjectViewModel.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/22/25.
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
    
    static var placeholder: Object = Object(
        name: "Rock",
        imagePath: "images/6834D814-5711-415F-99CD-4B6A0F698F1F.jpg",
        wins: [],
        loses: [],
        winCount: 5,
        timesUsed: 8)
    
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

@Observable
class ObjectViewModel {
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    var objects: [Object] = []
    
    func startListening() {
        db.collection("objects").addSnapshotListener { documentSnapshot, error in
            if let error {
                print("Snapshot listener error: \(error)")
                return
            }
            
            guard let documents = documentSnapshot?.documents else {
                print("No documents")
                return
            }
            
            self.objects = documents.compactMap { doc in
                do {
                    return try doc.data(as: Object.self)
                } catch {
                    print("Decoding error: \(error)")
                    return nil
                }
            }
        }
    }
}
