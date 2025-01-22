//
//  HomeViewModel.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/21/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage

@Observable
class HomeViewModel {
    
    private let storage = Storage.storage()
    
    var user: User?
    var credential: OAuthCredential?
    var uploadProgress: Progress?
    
    var isSigningIn = true
    
    func signIn() async {
        defer {
            isSigningIn = false
        }
        
        do {
            let signInResult = try await Auth.auth().signInAnonymously()
            user = signInResult.user
            credential = signInResult.credential
            
            print("Signed in as \(signInResult.user)")
        } catch {
            print("Auth error: \(error)")
        }
    }
    
    func upload(file: URL, name: String) async {
        guard let image = UIImage(contentsOfFile: file.path()) else {
            print("Could not load image from \(file)")
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            print("Could not create JPG data from image")
            return
        }
        
        let storageRef = storage.reference()
        let imageRef = storageRef.child("images/\(name).jpg")
        
        do {
            let metadata = try await imageRef.putDataAsync(imageData) { progress in
                self.uploadProgress = progress
                
                if let progress {
                    print("Upload progress: \(progress.fractionCompleted)")
                }
            }
            
            uploadProgress = nil
            print("Uploaded: \(metadata)")
        } catch {
            print("Upload error: \(error)")
        }
    }
}

