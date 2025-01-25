//
//  ObjectListener.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/25/25.
//

import FirebaseFirestore

@Observable class ObjectListener {
    var objects: [Object] = []
    
    func startListening() {
        let db = Firestore.firestore()
        db.collection("objects").addSnapshotListener { snapshot, error in
            if let error {
                Logger.log(error, message: "Objects snapshot listener error")
                return
            }
            
            snapshot?.documentChanges.forEach { diff in
                var newObject: Object
                do {
                    newObject = try diff.document.data(as: Object.self)
                } catch {
                    Logger.log(error, message: "Failed to parse Object from snapshot update")
                    return
                }
                
                switch diff.type {
                case .added:
                    self.objects.append(newObject)
                case .modified:
                    guard let index = self.objects.firstIndex(where: { $0.id == newObject.id }) else {
                        Logger.log("Failed to update object - could not find existing copy")
                        return
                    }
                    self.objects[index].update(with: newObject)
                case .removed:
                    guard let index = self.objects.firstIndex(where: { $0.id == newObject.id }) else {
                        Logger.log("Failed to update object - could not find existing copy")
                        return
                    }
                    self.objects.remove(at: index)
                }
            }
        }
    }
}
