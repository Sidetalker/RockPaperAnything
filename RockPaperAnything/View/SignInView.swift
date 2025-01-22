//
//  SignInView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/22/25.
//

import FirebaseAuth
import GameKitUI
import SwiftUI

struct SignInView: View {
    @ObservedObject var user: ObservableUser
    
    var body: some View {
        GKAuthenticationView { error in
            print("Error signing in to GC: \(error)")
        } authenticated: { player in
            print("Signed in \(player)")
            
            Task {
                do {
                    let credential = try await GameCenterAuthProvider.getCredential()
                    let result = try await Auth.auth().signIn(with: credential)
                    user.user = result.user
                    
                    print("Signed in \(result.user)")
                } catch {
                    print("Error signing in to Firebase: \(error)")
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var user = ObservableUser()
    SignInView(user: user)
}
