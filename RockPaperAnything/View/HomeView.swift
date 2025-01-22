//
//  HomeView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/21/25.
//

import SwiftUI
import ImagePlayground

struct HomeView: View {
    @State var viewModel = HomeViewModel()
    
    var body: some View {
        if viewModel.isSigningIn {
            ProgressView {
                Text("Signing In")
            }.task {
                await viewModel.signIn()
            }
        } else {
            TabView {
                ObjectsView(viewModel: $viewModel)
                    .tabItem {
                        Label("Objects", systemImage: "list.bullet")
                    }
            }
        }
    }
}

struct ObjectsView: View {
    @Binding var viewModel: HomeViewModel
    
    @State var isImagePlaygroundPresented = false
    @State var prompt = ""
    @State var imageUrl: URL?
    
    var body: some View {
        VStack {
            ZStack {
                AsyncImage(
                    url: imageUrl,
                    transaction: Transaction(animation: .easeInOut)
                ) { phase in
                    switch phase {
                    case .empty:
                        Text("Create your image")
                            .multilineTextAlignment(.center)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image(systemName: "wifi.slash")
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
                isImagePlaygroundPresented.toggle()
            }
            .padding(50)
        }
        .imagePlaygroundSheet(
            isPresented: $isImagePlaygroundPresented,
            concept: prompt
        ) { url in
            imageUrl = url
            Task {
                await viewModel.upload(file: url, name: prompt)
            }
        }
    }
}

#Preview {
    HomeView()
}
