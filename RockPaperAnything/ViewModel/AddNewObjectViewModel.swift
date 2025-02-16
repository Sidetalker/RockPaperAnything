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
    
    var uploadProgress: Progress?
    var uploadMetadata: StorageMetadata?
    var isGeneratingImage = false
    var generatedImage: UIImage?
    
    func upload(file: URL) async throws -> Object {
        guard let image = UIImage(contentsOfFile: file.path()) else {
            Logger.log(UploadError.imageLoadFail, message: "Could not load image from \(file)")
            throw UploadError.imageLoadFail
        }
        
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            Logger.log(UploadError.imageDataFail, message: "Could not create JPG data from image")
            throw UploadError.imageDataFail
        }
        
        let imagePath = "images/\(UUID().uuidString).jpg"
        let storageRef = storage.reference()
        let imageRef = storageRef.child(imagePath)
        
        _ = try await imageRef.putDataAsync(imageData) { progress in
            self.uploadProgress = progress
        }
        
        let downloadUrl = try await imageRef.downloadURL()
        
        return Object(name: "", imagePath: imagePath, downloadUrl: downloadUrl, wins: [], loses: [], winCount: 0, timesUsed: 0)
    }
    
    func delete() async {
        guard let path = uploadMetadata?.path else { return }
        
        let storageRef = storage.reference()
        let imageRef = storageRef.child(path)
        
        do {
            try await imageRef.delete()
        } catch {
            Logger.log(error, message: "Error deleting uploaded image")
        }
    }
    
    func generateImage(for name: String) async {
        isGeneratingImage = true
        generatedImage = nil
        
        generatedImage = await Network.generateImage(for: name)
        isGeneratingImage = false
    }
    
    func uploadGeneratedImage() async throws -> Object {
        guard let image = generatedImage else {
            throw UploadError.imageLoadFail
        }
        
        // Create a temporary file URL
        let temporaryDir = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = temporaryDir.appendingPathComponent(fileName)
        
        // Write image to temporary file
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            throw UploadError.imageDataFail
        }
        
        try imageData.write(to: fileURL)
        
        // Use existing upload function
        let object = try await upload(file: fileURL)
        
        // Clean up temporary file
        try? FileManager.default.removeItem(at: fileURL)
        
        return object
    }
}
