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
        }
    }
}

struct ObjectsView: View {
    @EnvironmentObject var user: User
    @State private var viewModel = ObjectViewModel()
    
    @State private var isImagePlaygroundPresented = false
    @State private var prompt = ""
    @State private var isAddingItem = false
    
    var body: some View {
        NavigationView {
            List(viewModel.objects) {
                ObjectCell(object: $0)
            }
            .navigationTitle("Objects")
            .toolbar {
                Button("", systemImage: "plus") {
                    isAddingItem = true
                }
            }
        }.fullScreenCover(isPresented: $isAddingItem) {
            AddNewObjectView(objects: viewModel.objects)
                .environment(\.modalMode, $isAddingItem)
        }.onAppear {
            viewModel.startListening()
        }
    }
}

struct ObjectCell: View {
    var object: Object
    
    var body: some View {
        HStack {
            ObjectImageView(object: object, size: 50)
            Text(object.name).padding(10)
        }
    }
}

#Preview("Objects List") {
    ObjectsView()
}
