//
//  ObjectViewModel.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/22/25.
//

import FirebaseFirestore
import SwiftUI

@Observable
class ObjectViewModel {
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
