//
//  AddNewObjectView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/22/25.
//

import SwiftUI

struct AddNewObjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ObjectListener.self) private var objectListener
    
    @State private var viewModel = AddNewObjectViewModel()
    
    @FocusState private var isPromptFocused
    @State private var isImagePlaygroundPresented = false
    @State private var prompt = ""
    @State private var imageUrl: URL?
    
    @State private var newObject: Object?
    
    private var isUploading: Bool {
        (viewModel.uploadProgress?.fractionCompleted ?? 1) < 1
    }
    
    var body: some View {
        NavigationStack {
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
                        .progressViewStyle(.circular)
                        .tint(.white)
                    }
                }
                TextField(
                    "Image Prompt",
                    text: $prompt
                ).onSubmit {
                    viewModel.uploadProgress = nil
                    imageUrl = nil
                    isImagePlaygroundPresented.toggle()
                }
                .focused($isPromptFocused)
                .submitLabel(.search)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
                .padding(.vertical, 30)
                
                if
                    let imageUrl,
                    viewModel.uploadProgress == nil
                {
                    Button(action: {
                        Task {
                            do {
                                self.newObject = try await viewModel.upload(file: imageUrl)
                            } catch {
                                Logger.log(error, message: "Upload error")
                            }
                        }
                    }) {
                        Label("Upload Image", systemImage: "icloud.and.arrow.up")
                    }
                } else if let newObject {
                    NavigationLink("Continue") {
                        ConfigureObjectView(objects: objectListener.objects, newObject: newObject, imageUrl: imageUrl)
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
            isPromptFocused = true
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
