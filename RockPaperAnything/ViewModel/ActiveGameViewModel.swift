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
    
    private let playerId = GKLocalPlayer.local.gamePlayerID
    private let db = Firestore.firestore()
    
    var match: Match
    var selectedObject: Object?
    var opponentObject: Object?
    var gameResult: GameResult?
    
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
            Logger.log(error, message: "Unexpected error resolving match")
        }
    }
    
    func select(object: Object) async {
        selectedObject = object
        
        do {
            if isCreator {
                try await endTurn(with: object)
            } else {
                try await endGame(with: object)
            }
        } catch {
            Logger.log(error, message: "Error resolving turn")
        }
    }
    
    private func endTurn(with object: Object) async throws {
        guard isCreator else {
            Logger.log(MatchError.developerError, message: "endTurn should only be used by the game creator")
            throw MatchError.developerError
        }
        
        guard let docId = match.id, let objectId = object.id else {
            Logger.log(MatchError.developerError, message: "Error resolving match or object id")
            throw MatchError.developerError
        }
        
        match.player1Selection = objectId
        try db.collection("games").document(docId).setData(from: match)
    }
    
    private func endGame(with object: Object) async throws {
        guard !isCreator else {
            Logger.log(MatchError.developerError, message: "endGame should only be used by player 2")
            throw MatchError.developerError
        }
        
        guard let docId = match.id, let objectId = object.id else {
            Logger.log(MatchError.developerError, message: "Error resolving match or object id")
            throw MatchError.developerError
        }
        
        let winner = try await match.determineWinner()
        match.player2Selection = objectId
        match.status = .ended
        match.winner = winner ?? ""
        try db.collection("games").document(docId).setData(from: match)
        
        if winner == nil {
            gameResult = .tied
        } else {
            gameResult = winner == playerId ? .won : .lost
        }
    }
}
