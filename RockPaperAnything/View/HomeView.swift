//
//  HomeView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/21/25.
//

import FirebaseAuth
import FirebaseStorage
import NukeUI
import SwiftUI
import ImagePlayground

struct ModalModeKey: EnvironmentKey {
    static let defaultValue = Binding<Bool>.constant(false) // < required
}

extension EnvironmentValues {
    var modalMode: Binding<Bool> {
        get {
            return self[ModalModeKey.self]
        }
        set {
            self[ModalModeKey.self] = newValue
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var user: User
    
    var body: some View {
        TabView {
            ObjectsView()
                .tabItem {
                    Label("Objects", systemImage: "list.bullet")
                }
            GamesView()
                .tabItem {
                    Label("Games", systemImage: "gamecontroller.fill")
                }
        }
    }
}

#Preview("Home View") {
    HomeView()
}
