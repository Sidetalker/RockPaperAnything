//
//  AddNewObjectView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/22/25.
//

import NukeUI
import FirebaseFirestore
import SwiftUI

struct AddNewObjectView: View {
    @Environment(\.dismiss) var dismiss
    
    @State var viewModel: AddNewObjectViewModel
    
    @FocusState private var isPromptFocused
    @State private var isImagePlaygroundPresented = false
    @State private var prompt = ""
    @State private var imageUrl: URL?
    
    @State private var newObject: Object?
    
    init(objects: [Object]) {
        viewModel = AddNewObjectViewModel(objects: objects)
    }
    
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
                                print("Upload error: \(error)")
                            }
                        }
                    }) {
                        Label("Upload Image", systemImage: "icloud.and.arrow.up")
                    }
                } else if let newObject {
                    NavigationLink("Continue") {
                        ConfigureObjectView(objects: viewModel.objects, newObject: newObject, imageUrl: imageUrl)
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

struct ConfigureObjectView: View {
    @Environment(\.modalMode) var modalMode
    @Environment(\.dismiss) var dismiss
    
    private let db = Firestore.firestore()
    let objects: [Object]
    let imageUrl: URL?
    
    @State var newObject: Object
    @State var objectStates: [BattleState]
    @State private var name = ""
    @FocusState private var isNameFocused
    
    var wins: Int { objectStates.count(where: { $0 == .wins }) }
    var losses: Int { objectStates.count(where: { $0 == .loses }) }
    var ties: Int { objectStates.count(where: { $0 == .ties }) }
    var isSaveDisabled: Bool { wins != losses || name.isEmpty || !isValidName }
    var isValidName: Bool { !objects.contains(where: { $0.name == name })}
    
    private let config = [
        GridItem(.fixed(80)),
        GridItem(.flexible(minimum: 50))
    ]
    
    init(objects: [Object], newObject: Object, imageUrl: URL?) {
        self.objects = objects
        self.newObject = newObject
        self.imageUrl = imageUrl
        self.objectStates = Array(repeating: BattleState.ties, count: objects.count)
    }
    
    var body: some View {
        VStack {
            AsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .mask(Circle())
            } placeholder: {
                ProgressView()
            }
            .frame(height: 200)
            TextField("Object Name", text: $name)
                .focused($isNameFocused)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .padding(20)
            Spacer()
            Text("Tap each object to set the battle result. There must be an equal number of winning and losing results.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            HStack {
                Spacer()
                Text("Wins: \(wins)")
                    .bold()
                    .foregroundStyle(Color.green)
                Spacer()
                Text("Losses: \(losses)")
                    .bold()
                    .foregroundStyle(Color.red)
                Spacer()
                Text("Ties: \(ties)")
                    .bold()
                    .foregroundStyle(Color.orange)
                Spacer()
            }
            Spacer()
            ScrollView {
                LazyVGrid(columns: config) {
                    ForEach(Array(objects.enumerated()), id: \.element) { index, object in
                        ObjectView(object: object, state: $objectStates[index])
                    }
                }.padding()
            }
            Spacer()
        }
        .navigationTitle("Configure Object")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    defer { modalMode.wrappedValue = false }
                    
                    newObject.name = name
                    newObject.wins = objects.enumerated().compactMap { index, object in
                        if let id = object.id, objectStates[index] == .wins {
                            return db.collection("objects").document(id)
                        } else { return nil }
                    }
                    newObject.loses = objects.enumerated().compactMap { index, object in
                        if let id = object.id, objectStates[index] == .loses {
                            return db.collection("objects").document(id)
                        } else { return nil }
                    }
                    
                    do {
                        try db.collection("objects").addDocument(from: newObject)
                    } catch {
                        print("Error adding new object: \(error)")
                    }
                }.disabled(isSaveDisabled)
            }
        }
    }
}

enum BattleState {
    case wins
    case loses
    case ties
    
    mutating func next() {
        switch self {
        case .ties:
            self = .wins
        case .wins:
            self = .loses
        case .loses:
            self = .ties
        }
    }
    
    var color: Color {
        switch self {
        case .ties: .clear
        case .wins: .green
        case .loses: .red
        }
    }
    
    var width: CGFloat {
        switch self {
        case .ties: 0
        case .wins, .loses: 4
        }
    }
}

struct ObjectView: View {
    let object: Object
    @Binding var state: BattleState
    
    var body: some View {
        VStack {
            ObjectImageView(object: object, size: 75)
                .overlay(Circle().stroke(state.color, lineWidth: state.width))
            Text(object.name)
        }.onTapGesture {
            state.next()
        }
    }
}

struct ObjectImageView: View {
    var object: Object
    var size: CGFloat
    
    @State private var imageUrl: URL?
    @State private var image: UIImage?
    
    var body: some View {
        LazyImage(url: imageUrl) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(width: size, height: size)
            } else if state.error != nil {
                Image(systemName: "exclamationmark.icloud")
                    .frame(width: size, height: size)
            } else {
                ProgressView()
                    .frame(width: 50, height: 50)
            }
        }.task {
            imageUrl = await object.getImageUrl()
        }
    }
}

#Preview("Add New") {
    AddNewObjectView(objects: [Object.placeholder])
}

#Preview("Configure") {
    NavigationView {
        ConfigureObjectView(objects: [Object.placeholder], newObject: Object.placeholder, imageUrl: URL(string: "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM="))
    }
}
