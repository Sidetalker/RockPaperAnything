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
}

enum GameResult {
    case won
    case lost
    case tied
}

struct ActiveGameView: View {
    @State private var viewModel: ActiveGameViewModel
    
    private let config = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(match: Match) {
        self.viewModel = ActiveGameViewModel(match: match)
    }
    
    var body: some View {
        VStack {
            if viewModel.isCreator {
                Text("You created this game")
            } else {
                Text("Someone else created this game")
            }
            
            switch viewModel.state {
            case .makeSelection:
                ScrollView {
                    LazyVGrid(columns: config) {
                        ForEach(viewModel.objects) { object in
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
            case .selectionMade:
                if let selectedObject = viewModel.selectedObject {
                    VStack {
                        Text("Waiting for another player")
                        ObjectImageView(object: selectedObject, size: 200)
                            .mask(Circle())
                        Text(selectedObject.name)
                    }
                } else {
                    ProgressView()
                }
            case .resolvingGame:
                ProgressView()
            case .finishedGame:
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
        .navigationTitle("Choose your move")
        .task {
            await viewModel.load()
        }
    }
}

#Preview("Active Game") {
    @Previewable var match = Match()
    ActiveGameView(match: match)
}
