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
    
    var games: [Match] = []
    
    func startListening() {
        GKLocalPlayer.local.register(self)
        
        db.collection("games").whereField("status", in: [1, 3]).addSnapshotListener { documentSnapshot, error in
            if let error {
                print("Snapshot listener error: \(error)")
                return
            }
            
            guard let documents = documentSnapshot?.documents else {
                self.games = []
                return
            }
            
            self.games = documents.compactMap { doc in
                do {
                    let match = try doc.data(as: Match.self)
                    
                    if match.player1Selection == "" && match.participants.first != GKLocalPlayer.local.gamePlayerID {
                        print("Filter out match where player 1 hasn't gone yet")
                        return nil
                    }
                    
                    return match
                } catch {
                    print("Decoding error: \(error)")
                    return nil
                }
            }
        }
    }
    
    func createMatch(_ match: GKTurnBasedMatch) -> Match? {
        let newMatch = Match(match)
        
        do {
            try db.collection("games").addDocument(from: newMatch)
            return newMatch
        } catch {
            print("Error creating match: \(error)")
            return nil
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
}
