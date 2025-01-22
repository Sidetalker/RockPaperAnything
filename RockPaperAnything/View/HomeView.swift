//
//  HomeView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/21/25.
//

import FirebaseAuth
import SwiftUI
import ImagePlayground

struct HomeView: View {
    @EnvironmentObject var user: User
    @State var viewModel = HomeViewModel()
    
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
    @State var viewModel = ObjectViewModel()
    
    @State private var isImagePlaygroundPresented = false
    @State private var prompt = ""
    @State private var imageUrl: URL?
    @State private var isAddingItem = false
    
    var body: some View {
        NavigationView {
            List {
                Text("test1")
                Text("test2")
                Text("test3")
            }
            .navigationTitle("Objects")
            .toolbar {
                Button("", systemImage: "plus") {
                    isAddingItem = true
                }
            }
        }.fullScreenCover(isPresented: $isAddingItem) {
            AddNewObjectView(viewModel: $viewModel)
        }
    }
}

struct AddNewObjectView: View {
    @EnvironmentObject var user: ObservableUser
    @Environment(\.dismiss) var dismiss
    
    @Binding var viewModel: ObjectViewModel
    
    @FocusState private var promptIsFocused: Bool
    @State private var isImagePlaygroundPresented = false
    @State private var prompt = ""
    @State private var name = ""
    @State private var imageUrl: URL?
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Step 1: Generate Your Image")
                    .bold()
                    .dynamicTypeSize(.large)
                Spacer().frame(height: 30)
                ZStack {
                    AsyncImage(
                        url: imageUrl,
                        transaction: Transaction(animation: .easeInOut)
                    ) { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "photo.fill")
                                .font(.system(size: 50, weight: .ultraLight))
                                .imageScale(.large)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 50, weight: .ultraLight))
                                .imageScale(.large)
                        default:
                            Text("Unknown phase")
                                .multilineTextAlignment(.center)
                        }
                    }
                    .brightness(viewModel.uploadProgress == nil ? 0 : -0.5)
                    .frame(width: 250)
                    
                    if let progress = viewModel.uploadProgress?.fractionCompleted {
                        ProgressView(value: progress) {
                            Text("Uploading")
                        } currentValueLabel: {
                            Text("\(Int(progress * 100))%")
                        }
                        .progressViewStyle(.circular)
                    }
                }
                TextField(
                    "Image Prompt",
                    text: $prompt
                ).onSubmit {
                    name = prompt
                    isImagePlaygroundPresented.toggle()
                }
                .focused($promptIsFocused)
                .submitLabel(.search)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
                .padding(.vertical, 30)
                TextField(
                    "Object Name",
                    text: $name
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
                Spacer().frame(height: 30)
                if let imageUrl {
                    Button(action: {
                        Task {
                            await viewModel.upload(file: imageUrl, name: name)
                        }
                    }) {
                        Label("Add Folder", systemImage: "folder.badge.plus")
                    }
                }
                Spacer()
            }
            .navigationTitle("Create New Object")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Task {
                            await viewModel.delete()
                            dismiss()
                        }
                    }.tint(.red)
                }
            }
        }.onAppear {
            promptIsFocused = true
        }.imagePlaygroundSheet(
            isPresented: $isImagePlaygroundPresented,
            concept: prompt
        ) { url in
            imageUrl = url
        }
    }
}

#Preview("Add New") {
    @Previewable @State var viewModel = ObjectViewModel()
    AddNewObjectView(viewModel: $viewModel)
}

#Preview("Objects List") {
    ObjectsView()
}
