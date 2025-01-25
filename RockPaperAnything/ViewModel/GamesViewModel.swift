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
        if var joinableGame = openGames.first, let docId = joinableGame.id {
            try await db.collection("games").document(docId).updateData([
                "participants": FieldValue.arrayUnion([playerId])
            ])
            joinableGame.participants.append(playerId)
            return joinableGame
        } else {
            var newMatch = Match(playerId: playerId)
            let reference = try db.collection("games").addDocument(from: newMatch)
            newMatch.id = reference.documentID
            return newMatch
        }
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
