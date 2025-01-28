//
//  ActiveGameView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/23/25.
//

import FirebaseFirestore
import GameKit
import SwiftUI

enum GameState {
    case makeSelection
    case selectionMade
    case resolvingGame
    case finishedGame
    
    func navTitle(result: GameResult?) -> String {
        switch self {
        case .makeSelection: return "Choose your move"
        case .selectionMade: return "Waiting for opponent"
        case .resolvingGame: return "Finalizing match..."
        case .finishedGame:
            guard let result else { return "Unknown result" }
            
            switch result {
            case .won: return "You won!"
            case .lost: return "You lost!"
            case .tied: return "Tie game!"
            }
        }
    }
}

enum GameResult: String {
    case won = "You Won"
    case lost = "You Lost"
    case tied = "Tie Game"
}

struct ActiveGameView: View {
    @Environment(\.objects) private var objects
    @State private var viewModel: ActiveGameViewModel
    
    @Namespace private var animationNamespace
    
    init(match: Match) {
        self.viewModel = ActiveGameViewModel(match: match)
    }
    
    var body: some View {
        ZStack {
            switch viewModel.state {
            case .makeSelection:
                ObjectSelectionView(viewModel, namespace: animationNamespace)
            case .selectionMade:
                SelectionMadeView(viewModel.selectedObject, namespace: animationNamespace)
            case .resolvingGame:
                ResolvingGameView(viewModel)
            case .finishedGame:
                FinishedGameView(viewModel)
            }
        }
        .animation(.easeIn, value: viewModel.state)
        .navigationTitle(viewModel.title)
        .task {
            await viewModel.load(using: objects)
        }
    }
}

struct ObjectSelectionView: View {
    @Environment(\.objects) private var objects
    private var viewModel: ActiveGameViewModel
    private var namespace: Namespace.ID
    
    private let config = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(_ viewModel: ActiveGameViewModel, namespace: Namespace.ID) {
        self.viewModel = viewModel
        self.namespace = namespace
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: config) {
                ForEach(objects) { object in
                    VStack {
                        Rectangle()
                            .fill(Color.clear)
                            .overlay {
                                ObjectImageView(object: object)
                            }
                            .matchedGeometryEffect(id: object.id, in: namespace)
                            .frame(width: 75, height: 75)
                        Text(object.name)
                            .matchedGeometryEffect(id: object.name, in: namespace)
                    }.onTapGesture {
                        Task {
                            await viewModel.select(object: object)
                        }
                    }
                }
            }.padding()
        }
    }
}

struct SelectionMadeView: View {
    private var selectedObject: Object?
    private var namespace: Namespace.ID
    
    init(_ object: Object?, namespace: Namespace.ID) {
        self.selectedObject = object
        self.namespace = namespace
    }
    
    var body: some View {
        VStack {
            if let selectedObject {
                VStack(spacing: 20) {
                    Text("You Played")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Rectangle()
                        .fill(Color.clear)
                        .overlay {
                            ObjectImageView(object: selectedObject)
                                .shadow(radius: 10)
                        }
                        .matchedGeometryEffect(id: selectedObject.id, in: namespace)
                        .frame(width: 200, height: 200)
                    
                    Text(selectedObject.name)
                        .matchedGeometryEffect(id: selectedObject.name, in: namespace)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding()
            } else {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

struct ResolvingGameView: View {
    private var viewModel: ActiveGameViewModel
    
    init(_ viewModel: ActiveGameViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ProgressView()
    }
}

struct FinishedGameView: View {
    private var viewModel: ActiveGameViewModel
    
    init(_ viewModel: ActiveGameViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack {
                if let selectedObject = viewModel.selectedObject {
                    VStack {
                        ObjectImageView(object: selectedObject)
                            .frame(width: 100, height: 100)
                            .shadow(radius: 10)
                        
                        Text("You")
                            .font(.headline)
                    }
                }
                
                Text("VS")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                if let opponentObject = viewModel.opponentObject {
                    VStack {
                        ObjectImageView(object: opponentObject)
                            .frame(width: 100, height: 100)
                            .shadow(radius: 10)
                        
                        Text("Opponent")
                            .font(.headline)
                    }
                }
            }
            
            Text(viewModel.resultText)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}

#Preview("Active Game") {
    @Previewable var match = Match()
    ActiveGameView(match: match)
}

#Preview("Selection Made") {
    @Previewable var object = Object.placeholder
    SelectionMadeView(object, namespace: Namespace().wrappedValue)
}
