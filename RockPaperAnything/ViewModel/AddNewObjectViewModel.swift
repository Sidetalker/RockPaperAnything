//
//  AddNewObjectViewModel.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/22/25.
//

import FirebaseStorage
import SwiftUI

enum UploadError: Error {
    case imageLoadFail
    case imageDataFail
}

@Observable
class AddNewObjectViewModel {
    private let storage = Storage.storage()
    
    var objects: [Object]
    var uploadProgress: Progress?
    var uploadMetadata: StorageMetadata?
    
    init(objects: [Object]) {
        self.objects = objects
    }
    
    func upload(file: URL) async throws -> Object {
        guard let image = UIImage(contentsOfFile: file.path()) else {
            print("Could not load image from \(file)")
            throw UploadError.imageLoadFail
        }
        
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            print("Could not create JPG data from image")
            throw UploadError.imageDataFail
        }
        
        let imagePath = "images/\(UUID().uuidString).jpg"
        let storageRef = storage.reference()
        let imageRef = storageRef.child(imagePath)
        
        _ = try await imageRef.putDataAsync(imageData) { progress in
            self.uploadProgress = progress
            
            if let progress {
                print("Upload progress: \(progress.fractionCompleted)")
            }
        }
        
        return Object(name: "", imagePath: imagePath, wins: [], loses: [], winCount: 0, timesUsed: 0)
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
