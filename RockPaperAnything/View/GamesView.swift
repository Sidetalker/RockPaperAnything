//
//  GamesView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/23/25.
//

import GameKitUI
import SwiftUI

struct GamesView: View {
    @State private var viewModel = GamesViewModel()
    @State private var isShowingMatchmaking: Bool = false
    @State private var navStack: [Match] = []
    
    var body: some View {
        NavigationStack(path: $navStack) {
            VStack {
                Button {
                    isShowingMatchmaking.toggle()
                } label: {
                    Text("Create New Game")
                }.sheet(isPresented: $isShowingMatchmaking) { GKTurnBasedMatchmakerView(
                    minPlayers: 2,
                    maxPlayers: 2,
                    inviteMessage: "Let us play together!"
                ) {
                    print("Player Canceled")
                } failed: { error in
                    print("Match Making Failed: \(error)")
                } started: { match in
                    print("Match Started: \(match)")
                    
                    if let existingMatch = viewModel.games.first(where: { $0.matchId == match.matchID }) {
                        print("Selected existing match")
                        navStack.append(existingMatch)
                        return
                    }
                    
                    guard let match = viewModel.createMatch(match) else {
                        print("Failed to initialize match")
                        return
                    }
                    navStack.append(match)
                }.ignoresSafeArea(edges: .bottom)}
                
                List(viewModel.games) { game in
                    NavigationLink(value: game) {
                        Text("Created: \(game.creationDate)")
                    }
                }.navigationDestination(for: Match.self) { match in
                    ActiveGameView(match: match)
                }.navigationTitle("Games")
            }.onAppear {
                viewModel.startListening()
            }
        }
    }
}

#Preview("Games View") {
    GamesView()
}
