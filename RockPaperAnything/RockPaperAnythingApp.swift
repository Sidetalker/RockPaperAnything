//
//  RockPaperAnythingApp.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/21/25.
//

import FirebaseAuth
import FirebaseCore
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct RockPaperAnythingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var user = ObservableUser()
    
    var body: some Scene {
        WindowGroup {
            if let user = user.user {
                HomeView()
                    .environmentObject(user)
            } else {
                LoginView(user: user)
            }
        }
    }
}
