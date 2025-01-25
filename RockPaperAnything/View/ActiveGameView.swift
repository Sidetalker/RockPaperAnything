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

enum GameResult {
    case won
    case lost
    case tied
}

struct ActiveGameView: View {
    @Environment(ObjectListener.self) private var objectListener
    @State private var viewModel: ActiveGameViewModel
    
    init(match: Match) {
        self.viewModel = ActiveGameViewModel(match: match)
    }
    
    var body: some View {
        VStack {
            switch viewModel.state {
            case .makeSelection:
                ObjectSelectionView(viewModel)
            case .selectionMade:
                SelectionMadeView(viewModel.selectedObject)
            case .resolvingGame:
                ResolvingGameView(viewModel)
            case .finishedGame:
                FinishedGameView(viewModel)
            }
        }
        .navigationTitle(viewModel.title)
        .task {
            await viewModel.load(using: objectListener.objects)
        }
    }
}

struct ObjectSelectionView: View {
    @Environment(ObjectListener.self) private var objectListener
    private var viewModel: ActiveGameViewModel
    
    private let config = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(_ viewModel: ActiveGameViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: config) {
                ForEach(objectListener.objects) { object in
                    VStack {
                        ObjectImageView(object: object, size: 75)
                            .mask(Circle())
                        Text(object.name)
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
    
    init(_ object: Object?) {
        self.selectedObject = object
    }
    
    var body: some View {
        VStack {
            if let selectedObject {
                VStack(spacing: 20) {
                    Text("You Played")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    ObjectImageView(object: selectedObject, size: 200)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .padding()
                    
                    Text(selectedObject.name)
                        .font(.headline)
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
        switch viewModel.gameResult {
        case .won:
            Text("You Won")
        case .lost:
            Text("You Lost")
        case .tied:
            Text("Tie Game")
        case nil:
            ProgressView()
        }
    }
}

#Preview("Active Game") {
    @Previewable var match = Match()
    ActiveGameView(match: match)
}

#Preview("Selection Made") {
    @Previewable var object = Object(name: "Rock", imagePath: "images/2CABC044-1344-40C5-A458-27E394A1DD31.jpg", wins: [], loses: [], winCount: 0, timesUsed: 0)
    SelectionMadeView(object)
}
