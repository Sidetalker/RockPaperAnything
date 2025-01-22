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
    @State var viewModel = ObjectViewModel()
    
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
            AddNewObjectView()
        }.onAppear {
            viewModel.startListening()
        }
    }
}

struct ObjectCell: View {
    var object: Object
    @State var imageUrl: URL?
    
    var body: some View {
        HStack {
            LazyImage(url: imageUrl) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(Circle())
                        .frame(width: 50, height: 50)
                } else if state.error != nil {
                    Image(systemName: "exclamationmark.icloud")
                } else {
                    ProgressView()
                        .frame(width: 50, height: 50)
                }
            }
            Text(object.name).padding(10)
        }.task {
            let storage = Storage.storage()
            let storageRef = storage.reference(withPath: object.imagePath)
            
            do {
                imageUrl = try await storageRef.downloadURL()
            } catch {
                print("Error getting URL: \(error)")
            }
        }
    }
}

struct AddNewObjectView: View {
    @EnvironmentObject var user: ObservableUser
    @Environment(\.dismiss) var dismiss
    
    @State var viewModel = AddNewObjectViewModel()
    
    @FocusState private var promptIsFocused: Bool
    @State private var isImagePlaygroundPresented = false
    @State private var prompt = ""
    @State private var name = ""
    @State private var imageUrl: URL?
    
    private var isUploading: Bool {
        (viewModel.uploadProgress?.fractionCompleted ?? 1) < 1
    }
    
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
                    .brightness(isUploading ? -0.5 : 0)
                    .frame(width: 250)
                    
                    if
                        let progress = viewModel.uploadProgress?.fractionCompleted,
                        isUploading
                    {
                        ProgressView(value: progress) {
                            Text("Uploading")
                        } currentValueLabel: {
                            Text("\(Int(progress * 100))%")
                        }
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
                
                if let imageUrl, !(viewModel.uploadProgress?.isFinished ?? false) {
                    Button(action: {
                        Task {
                            await viewModel.upload(file: imageUrl)
                        }
                    }) {
                        Label("Upload Image", systemImage: "icloud.and.arrow.up")
                    }
                } else if imageUrl != nil {
                    Button(action: {
                        return
                    }) {
                        Text("Continue")
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
//                            await viewModel.delete()
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
    AddNewObjectView()
}

#Preview("Objects List") {
    @Previewable @State var viewModel: ObjectViewModel = {
        let vm = ObjectViewModel()
        vm.objects = [Object.placeholder]
        return vm
    }()
    
    ObjectsView(viewModel: viewModel)
}
