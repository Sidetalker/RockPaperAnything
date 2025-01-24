//
//  GamesView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/23/25.
//

import GameKit
import SwiftUI

enum GameView: String, CaseIterable, Identifiable {
    var id: Self { return self }
    
    case new = "Join Existing"
    case ongoing = "In Progress"
    case completed = "Completed"
}

struct GamesView: View {
    @State private var viewModel = GamesViewModel()
    @State private var isShowingMatchmaking: Bool = false
    @State private var navStack: [Match] = []
    @State private var selection: GameView = .new
    
    var body: some View {
        NavigationStack(path: $navStack) {
            Picker("Games View", selection: $selection) {
                ForEach(GameView.allCases) { gameView in
                    Text(gameView.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            switch selection {
            case .new:
//                VStack {
//                    Spacer()
//                    Button {
//                        isShowingMatchmaking.toggle()
//                    } label: {
//                        Text("Start Matchmaking")
//                    }.sheet(isPresented: $isShowingMatchmaking) { GKTurnBasedMatchmakerView(
//                        minPlayers: 2,
//                        maxPlayers: 2,
//                        inviteMessage: "Come play Rock, Paper, Anything!"
//                    ) {
//                        print("Player Canceled")
//                    } failed: { error in
//                        print("Match Making Failed: \(error)")
//                    } started: { match in
//                        print("Match Started: \(match)")
//                        
//                        if let existingMatch = viewModel.games.first(where: { $0.matchId == match.matchID }) {
//                            print("Selected existing match")
//                            navStack.append(existingMatch)
//                            return
//                        }
//                        
//                        guard let match = viewModel.createMatch(match) else {
//                            print("Failed to initialize match")
//                            return
//                        }
//                        navStack.append(match)
//                    }.ignoresSafeArea(edges: .bottom)}
//                    Spacer()
//                }.navigationDestination(for: Match.self) { match in
//                    ActiveGameView(match: match)
//                }.navigationTitle("Games")
                
                ContentUnavailableView {
                    Label(viewModel.openGames.isEmpty ?
                          "No Joinable Games" :
                            "\(viewModel.openGames.count) Ongoing Games",
                          systemImage: "globe.americas")
                } actions: {
                    Button(viewModel.openGames.isEmpty ?
                           "Start New Game" : "Join Game") {
                        Task {
                            do {
                                let match = try await viewModel.joinOrStartGame()
                                navStack.append(match)
                            } catch {
                                print("Error joining game: \(error)")
                            }
                        }
                    }
                }.navigationDestination(for: Match.self) { match in
                    ActiveGameView(match: match)
                }.navigationTitle("Games")
            case .ongoing:
                List(viewModel.activeGames) { game in
                    NavigationLink(value: game) {
                        Text("Created: \(game.creationDate)")
                    }
                }.navigationDestination(for: Match.self) { match in
                    ActiveGameView(match: match)
                }.navigationTitle("Games")
            case .completed:
                List(viewModel.completedGames) { game in
                    NavigationLink(value: game) {
                        Text("Created: \(game.creationDate)")
                    }
                }.navigationDestination(for: Match.self) { match in
                    ActiveGameView(match: match)
                }.navigationTitle("Games")
            }
        }
        .onAppear {
            viewModel.startListening()
        }
    }
}

#Preview("Games View") {
    GamesView()
}
