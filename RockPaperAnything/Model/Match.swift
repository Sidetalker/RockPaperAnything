//
//  Object.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/23/25.
//

import GameKit
import FirebaseFirestore
import SwiftUI

struct Match: Codable, Hashable, Identifiable {
    @DocumentID var id: String?
    
    var matchId: String
    var creationDate: Date
    var status: Int
    var participants: [String]
    var player1Selection: String
    var player2Selection: String
    
    init(_ match: GKTurnBasedMatch) {
        matchId = match.matchID
        creationDate = Date()
        status = match.status.rawValue
        participants = match.participants.compactMap { $0.player?.gamePlayerID }
        player1Selection = ""
        player2Selection = ""
    }
    
    init() {
        matchId = "placeholder"
        creationDate = Date()
        status = 0
        participants = []
        player1Selection = ""
        player2Selection = ""
    }
    
    func data() throws -> Data {
        return try MatchData(self).data()
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
