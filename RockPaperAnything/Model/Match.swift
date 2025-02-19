//
//  Object.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/23/25.
//

import GameKit
import FirebaseFirestore
import SwiftUI

enum MatchError: Error {
    case creationError
    case missingParticipants
    case notFinished
    case developerError
}

extension GKTurnBasedMatch.Status: Codable { }

struct Match: Codable, Hashable, Identifiable {
    @DocumentID var id: String?
    
    var matchId: String
    var creationDate: Date
    var status: GKTurnBasedMatch.Status
    var participants: [String]
    var player1Selection: String
    var player2Selection: String
    var winner: String
    var flavorText: String
    
    init(playerId: String) {
        matchId = "non-gc-match"
        creationDate = Date()
        status = .open
        participants = [playerId]
        player1Selection = ""
        player2Selection = ""
        winner = ""
        flavorText = ""
    }
    
    init() {
        matchId = "placeholder"
        creationDate = Date()
        status = .open
        participants = []
        player1Selection = ""
        player2Selection = ""
        winner = ""
        flavorText = ""
    }
    
    func determineWinner() async throws -> String? {
        if !winner.isEmpty, let winnerIndex = participants.firstIndex(of: winner) {
            return participants[winnerIndex]
        }
        
        guard
            participants.count == 2,
            let player1 = participants.first,
            let player2 = participants.dropFirst().first
        else {
            throw MatchError.missingParticipants
        }
        
        guard !player1Selection.isEmpty && !player2Selection.isEmpty else {
            throw MatchError.notFinished
        }
        
        let db = Firestore.firestore()
        
        let player1Object = try await db.collection("objects").document(player1Selection).getDocument().data(as: Object.self)
        let player2Object = try await db.collection("objects").document(player2Selection).getDocument().data(as: Object.self)
        
        if
            player1Object.wins.contains(where: { $0.documentID == player2Object.id }) ||
            player2Object.loses.contains(where: { $0.documentID == player1Object.id })
        {
            return player1
        } else if
            player2Object.wins.contains(where: { $0.documentID == player1Object.id }) ||
            player1Object.loses.contains(where: { $0.documentID == player2Object.id })
        {
            return player2
        } else {
            return nil
        }
    }
}

struct MatchData: Codable {
    var player1Selection: String?
    var player2Selection: String?
    
    init(_ match: Match) {
        self.player1Selection = match.player1Selection
        self.player2Selection = match.player2Selection
    }
    
    func data() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}
