//
//  ActiveGameViewModel.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/23/25.
//

import EventSource
import GameKit
import FirebaseFirestore
import Foundation
import SwiftUI

@Observable
public class ActiveGameViewModel {
    
    private let playerId = GKLocalPlayer.local.gamePlayerID
    private let db = Firestore.firestore()
    
    var match: Match
    var selectedObject: Object?
    var opponentObject: Object?
    var gameResult: GameResult?
    var explanation: String = ""
    
    var explanationDisplay: String {
        if !explanation.contains("|") { return "" }
        else {
            let splitSubstrings = explanation.split(separator: "|")
            guard splitSubstrings.count == 2 else { return "" }
            return String(splitSubstrings[1])
        }
    }
    
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
        } else if gameResult == .tied && match.winner.isEmpty && match.player1Selection != match.player2Selection {
            return .tiebreaker
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
        
        match.player2Selection = objectId
        let winner = try await match.determineWinner()
        
        if winner != nil {
            match.status = .ended
            match.winner = winner ?? ""
        }
        
        try db.collection("games").document(docId).setData(from: match)
        
        if winner == nil {
            gameResult = .tied
        } else {
            gameResult = winner == playerId ? .won : .lost
        }
    }
    
    func startTiebreaker() async {
        guard let selectedObject = selectedObject,
              let opponentObject = opponentObject else { return }
        
        let eventSource = EventSource()
        let urlRequest = Network.deepSeekRequest(for: selectedObject, vs: opponentObject)
        let dataTask = await eventSource.dataTask(for: urlRequest)
        
        for await event in await dataTask.events() {
            switch event {
            case .event(let event):
                if let data = event.data?.data(using: .utf8) {
                    do {
                        let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: data)
                        if let content = chunk.choices.first?.delta.content {
                            explanation += content
                        }
                    } catch {
                        print("Error decoding chunk: \(error)")
                    }
                }
            case .error(let error):
                print("Error: \(error)")
            case .closed:
                // Check if we have a complete response with a winner
                if explanation.contains("|") {
                    let parts = explanation.split(separator: "|")
                    if parts.count == 2 {
                        let winner = String(parts[0])
                        if winner == selectedObject.name {
                            resolveTiebreaker(winner: true, flavor: String(parts[1]))
                        } else if winner == opponentObject.name {
                            resolveTiebreaker(winner: false, flavor: String(parts[1]))
                        }
                    }
                }
            default:
                break
            }
        }
    }
    
    func resolveTiebreaker(winner: Bool, flavor: String) {
        if winner {
            gameResult = .won
        } else {
            gameResult = .lost
        }
        
        // Update the match in Firestore with the new winner
        if let docId = match.id {
            match.winner = winner ? playerId : (match.participants.first { $0 != playerId } ?? "")
            match.flavorText = flavor
            match.status = .ended
            try? db.collection("games").document(docId).setData(from: match)
        }
    }
}
