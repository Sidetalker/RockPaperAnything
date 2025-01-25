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
                Logger.log(error, message: "Objects snapshot listener error")
                return
            }
            
            guard let documents = documentSnapshot?.documents else { return }
            
            self.objects = documents.compactMap { doc in
                do {
                    return try doc.data(as: Object.self)
                } catch {
                    Logger.log(error, message: "Object decoding error")
                    return nil
                }
            }
        }
    }
}
