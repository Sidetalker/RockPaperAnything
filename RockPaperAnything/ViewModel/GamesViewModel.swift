//
//  GamesViewModel.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/23/25.
//

import GameKit
import FirebaseFirestore
import SwiftUI

@Observable
class GamesViewModel: NSObject, GKLocalPlayerListener {
    private let db = Firestore.firestore()
    private let playerId = GKLocalPlayer.local.gamePlayerID
    
    var myGames: [Match] = []
    var openGames: [Match] = []
    
    var activeGames: [Match] { myGames.filter({ $0.status == .open }) }
    var completedGames: [Match] { myGames.filter({ $0.status == .ended }) }
    
    func startListening() {
        GKLocalPlayer.local.register(self)
        
        db.collection("games")
            .whereField("participants", arrayContains: playerId)
            .addSnapshotListener { documentSnapshot, error in
                if let error {
                    print("Snapshot listener error: \(error)")
                    return
                }
                
                guard let documents = documentSnapshot?.documents else {
                    self.myGames = []
                    return
                }
                
                self.myGames = documents.compactMap { doc in
                    do {
                        let match = try doc.data(as: Match.self)
                        return match
                    } catch {
                        print("Decoding error: \(error)")
                        return nil
                    }
                }
            }
        
        db.collection("games")
            .whereField("status", in: [1, 3])
            .whereField("player1Selection", isNotEqualTo: "")
            .addSnapshotListener { documentSnapshot, error in
                if let error {
                    print("Snapshot listener error: \(error)")
                    return
                }
                
                guard let documents = documentSnapshot?.documents else {
                    self.openGames = []
                    return
                }
                
                self.openGames = documents.compactMap { doc in
                    do {
                        let match = try doc.data(as: Match.self)
                        
                        // Filter out matches where I'm a participant
                        if match.participants.contains(where: { $0 == self.playerId }) { return nil }
                        
                        return match
                    } catch {
                        print("Decoding error: \(error)")
                        return nil
                    }
                }
            }
    }
    
    func joinOrStartGame() async throws -> Match {
        let request = GKMatchRequest()
        request.maxPlayers = 2
        request.minPlayers = 2
        
        let gkMatch = try await GKTurnBasedMatch.find(for: request)
        
        // Look up existing game
        let snapshot = try await db.collection("games").whereField("matchId", isEqualTo: gkMatch.matchID).getDocuments()
        
        if snapshot.documents.isEmpty {
            // Create new game
            var match = Match(gkMatch)
            let reference = try db.collection("games").addDocument(from: match)
            match.id = reference.documentID
            return match
        } else if var existingMatch = try snapshot.documents.first?.data(as: Match.self), let docId = existingMatch.id {
            // Update existing game to include new player
            try await db.collection("games").document(docId).updateData([
                "participants": FieldValue.arrayUnion([playerId])
            ])
            existingMatch.participants.append(playerId)
            return existingMatch
        }
        
        throw MatchError.creationError
    }
    
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        let playerId = player.gamePlayerID
        let matchId = match.matchID
        
        print("Match event fired for \(matchId)")
        
        guard match.participants.contains(where: { $0.player?.gamePlayerID == playerId }) else {
            print("Player received event for a match they're not part of...")
            return
        }
        
        if match.status == .ended {
            print("Cleaning up match")
            Task {
                try await db.collection("games").document(matchId).updateData(["status": match.status.rawValue])
                print("Match status updated")
            }
        }
    }
    
    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        print("Match ended")
    }
    
    func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        print("Player wants to quit")
        print("Cleaning up match")
        Task {
            if match.currentParticipant?.player?.gamePlayerID == player.gamePlayerID {
                try await match.participantQuitInTurn(
                    with: .quit,
                    nextParticipants: match.participants.filter({ $0.player?.gamePlayerID != player.gamePlayerID }),
                    turnTimeout: 90 * 24 * 60 * 60,
                    match: Data())
                print("Quit match in turn")
            } else {
                try await match.participantQuitOutOfTurn(with: .quit)
                print("Quit match out of turn")
            }
            
            let matchSnapshot = try await db.collection("games").whereField("matchId", isEqualTo: match.matchID).getDocuments()
            guard let docId = matchSnapshot.documents.first?.documentID else {
                print("Unable to find match in db")
                return
            }
            try await db.collection("games").document(docId).updateData(["status": 2])
            print("Match status in db updated")
        }
    }
    
    func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
        print("cancelled that shit")
    }
}
