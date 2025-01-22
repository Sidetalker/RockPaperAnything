//
//  AddNewObjectViewModel.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/22/25.
//

import FirebaseFirestore
import FirebaseStorage
import SwiftUI

@Observable
class AddNewObjectViewModel {
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    var uploadProgress: Progress?
    var uploadMetadata: StorageMetadata?
    
    func upload(file: URL) async {
        guard let image = UIImage(contentsOfFile: file.path()) else {
            print("Could not load image from \(file)")
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            print("Could not create JPG data from image")
            return
        }
        
        let storageRef = storage.reference()
        let imageRef = storageRef.child("images/\(UUID().uuidString).jpg")
        
        do {
            let metadata = try await imageRef.putDataAsync(imageData) { progress in
                self.uploadProgress = progress
                
                if let progress {
                    print("Upload progress: \(progress.fractionCompleted)")
                }
            }
            
            print("Uploaded: \(metadata)")
        } catch {
            print("Upload error: \(error)")
        }
    }
    
    func delete() async {
        guard let path = uploadMetadata?.path else {
            print("Nothing to delete")
            return
        }
        
        let storageRef = storage.reference()
        let imageRef = storageRef.child(path)
        
        do {
            try await imageRef.delete()
        } catch {
            print("Deletion error: \(error)")
        }
    }
}
