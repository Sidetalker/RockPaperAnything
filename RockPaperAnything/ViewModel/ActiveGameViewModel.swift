//
//  ActiveGameViewModel.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/23/25.
//

import GameKit
import FirebaseFirestore
import SwiftUI

@Observable
public class ActiveGameViewModel {
    var match: Match
    var selectedObject: Object?
    var opponentObject: Object?
    var gameResult: GameResult?
    
    private let playerId = GKLocalPlayer.local.gamePlayerID
    
    var isCreator: Bool {
        playerId == match.participants.first
    }
    
    var state: GameState {
        if (match.player1Selection.isEmpty && isCreator) || (match.player2Selection.isEmpty && !isCreator) {
            return .makeSelection
        } else if !match.player1Selection.isEmpty && match.player2Selection.isEmpty && isCreator {
            return .selectionMade
        } else if gameResult == nil {
            return .resolvingGame
        } else {
            return .finishedGame
        }
    }
    
    var title: String {
        return state.navTitle(result: gameResult)
    }
    
    var resultText: String {
        return gameResult?.rawValue ?? "Unknown Result"
    }
    
    init(match: Match) {
        self.match = match
    }
    
    func load(using objects: [Object]) async {
        let db = Firestore.firestore()
        
        await checkWinner(objects: objects)
        
        guard gameResult == nil else { return }
        
        guard let matchId = match.id else {
            Logger.log("Error resolving matchId to start listening")
            return
        }
        
        db.collection("games").document(matchId).addSnapshotListener { snapshot, error in
            guard let snapshot else { return }
            do {
                self.match = try snapshot.data(as: Match.self)
                Task { await self.checkWinner(objects: objects) }
            } catch {
                Logger.log(error, message: "Error decoding realtime match update")
                print()
            }
        }
    }
    
    func checkWinner(objects: [Object]) async {
        selectedObject = objects.first(where: { $0.id == (isCreator ? match.player1Selection : match.player2Selection) })
        opponentObject = objects.first(where: { $0.id == (isCreator ? match.player2Selection : match.player1Selection) })
        
        do {
            let winner = try await match.determineWinner()
            
            if winner == nil {
                gameResult = .tied
            } else {
                gameResult = winner == playerId ? .won : .lost
            }
            
            return // Return early, we good to go
        } catch is MatchError {
            // Expected if the match has not completed, continue as usual
        } catch {
            print("Unexpected error resolving match: \(error)")
        }
    }
    
    func select(object: Object) async {
        selectedObject = object
        
        do {
            let db = Firestore.firestore()
            
            guard let docId = match.id, let objectId = object.id else {
                print("Error resolving match or object id")
                return
            }
            
            if isCreator {
                match.player1Selection = objectId
                try db.collection("games").document(docId).setData(from: match)
                
                let currentMatch = try await GKTurnBasedMatch.load(withID: match.matchId)
                let nextParticipants = currentMatch.participants.filter({ $0.player?.gamePlayerID != GKLocalPlayer.local.gamePlayerID })
                try await currentMatch.endTurn(
                    withNextParticipants: nextParticipants,
                    turnTimeout: 90 * 24 * 60 * 60,
                    match: match.data())
            } else {
                match.player2Selection = objectId
                match.status = .ended
                try db.collection("games").document(docId).setData(from: match)
                
                let currentMatch: GKTurnBasedMatch = try await GKTurnBasedMatch.load(withID: match.matchId)
                let winner = try await match.determineWinner()
                for participant in currentMatch.participants {
                    guard let winner else {
                        participant.matchOutcome = .tied
                        continue
                    }
                    
                    participant.matchOutcome = winner == participant.player?.gamePlayerID ? .won : .lost
                }
                try await currentMatch.endMatchInTurn(withMatch: match.data())
                
                if winner == nil {
                    gameResult = .tied
                } else {
                    gameResult = winner == playerId ? .won : .lost
                }
            }
        } catch {
            print("Error resolving turn \(error)")
        }
    }
}
