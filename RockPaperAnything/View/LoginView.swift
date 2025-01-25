//
//  SignInView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/22/25.
//

import FirebaseCrashlytics
import FirebaseAuth
import GameKitUI
import SwiftUI

struct LoginView: View {
    @State var user: ObservableUser
    @State private var isShowingGKAuth = false
    
    var body: some View {
        VStack {
            LoginHeaderView()
                .frame(height: 325)
            Spacer()
            
            if !isShowingGKAuth {
                Button {
                    isShowingGKAuth.toggle()
                } label: {
                    HStack {
                        Image(.gameCenterIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Connect to Game Center")
                    }
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
            } else {
                GKAuthenticationView { error in
                    Logger.log(error, message: "Error signing in to GC")
                } authenticated: { player in
                    Crashlytics.crashlytics().setUserID(player.gamePlayerID)
                    
                    Task {
                        do {
                            let credential = try await GameCenterAuthProvider.getCredential()
                            let result = try await Auth.auth().signIn(with: credential)
                            user.user = result.user
                        } catch {
                            Logger.log(error, message: "Error signing into Firebase")
                        }
                    }
                }
            }
            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var user = ObservableUser()
    LoginView(user: user)
}
