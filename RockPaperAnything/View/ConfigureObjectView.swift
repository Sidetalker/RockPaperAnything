//
//  ConfigureObjectView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/22/25.
//

import NukeUI
import FirebaseFirestore
import SwiftUI

struct ConfigureObjectView: View {
    @Environment(\.modalMode) var modalMode
    
    private let db = Firestore.firestore()
    let objects: [Object]
    let imageUrl: URL?
    
    @State private var newObject: Object
    @State private var objectStates: [BattleState]
    @State private var name = ""
    @FocusState private var isNameFocused
    
    var wins: Int { objectStates.count(where: { $0 == .wins }) }
    var losses: Int { objectStates.count(where: { $0 == .loses }) }
    var ties: Int { objectStates.count(where: { $0 == .ties }) }
    var isSaveDisabled: Bool { wins != losses || name.isEmpty || !isValidName }
    var isValidName: Bool { !objects.contains(where: { $0.name == name })}
    
    private let config = [
        GridItem(.flexible()),
        GridItem(.flexible())
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
                    
                    objectStates.append(.ties)
                    
                    do {
                        try db.collection("objects").addDocument(from: newObject)
                    } catch {
                        objectStates.removeLast()
                        Logger.log(error, message: "Error adding new object")
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
    
    var body: some View {
        LazyImage(object: object) { state in
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
        }
    }
}

#Preview("Configure") {
    NavigationView {
        ConfigureObjectView(objects: [Object.placeholder], newObject: Object.placeholder, imageUrl: URL(string: "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM="))
    }
}
