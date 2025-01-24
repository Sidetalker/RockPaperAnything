//
//  ActiveGameView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/23/25.
//

import FirebaseFirestore
import GameKit
import SwiftUI

struct ActiveGameView: View {
    @State var match: Match
    @State private var objects: [Object] = []
    @State private var selectedObject: Object?
    
    private var isCreator: Bool {
        GKLocalPlayer.local.gamePlayerID == match.participants.first
    }
    
    private let config = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            if isCreator {
                Text("You created this game")
            } else {
                Text("Someone else created this game")
            }
            
            if match.player1Selection != "" {
                VStack {
                    Text("Waiting for another player")
                    if let selectedObject {
                        ObjectImageView(object: selectedObject, size: 200)
                            .mask(Circle())
                        Text(selectedObject.name)
                    }
                }
            } else {
                if selectedObject == nil {
                    ScrollView {
                        LazyVGrid(columns: config) {
                            ForEach(objects) { object in
                                VStack {
                                    ObjectImageView(object: object, size: 75)
                                        .mask(Circle())
                                    Text(object.name)
                                }.onTapGesture {
                                    selectedObject = object
                                }
                            }
                        }.padding()
                    }
                } else if let selectedObject, let selectedId = selectedObject.id {
                    ObjectImageView(object: selectedObject, size: 200)
                        .mask(Circle())
                    Button {
                        Task {
                            let db = Firestore.firestore()
                            let matchSnapshot = try await db.collection("games").whereField("matchId", isEqualTo: $match.wrappedValue.matchId).getDocuments()
                            guard let docId = matchSnapshot.documents.first?.documentID else {
                                print("Unable to find match in db")
                                return
                            }
                            let data: [String: String] = ["player1Selection": selectedId]
                            try await db.collection("games").document(docId).updateData(data)
                            match.player1Selection = selectedId
                            print("Set player1Selection")
                            
                            do {
                                let currentMatch = try await GKTurnBasedMatch.load(withID: match.matchId)
                                let nextParticipants = currentMatch.participants.filter({ $0.player?.gamePlayerID != GKLocalPlayer.local.gamePlayerID })
                                try await currentMatch.endTurn(
                                    withNextParticipants: nextParticipants,
                                    turnTimeout: 90 * 24 * 60 * 60,
                                    match: match.data())
                                print("Passed turn")
                            } catch {
                                print("Error passing turn \(error)")
                            }
                        }
                    } label: {
                        Text("Lock it in")
                    }.padding(50)
                }
            }
        }
        .navigationTitle("Choose your move")
        .task {
            let db = Firestore.firestore()
            
            do {
                let snapshot = try await db.collection("objects").getDocuments(source: .cache)
                objects = try snapshot.documents.map { doc in
                    return try doc.data(as: Object.self)
                }
                
                if isCreator && match.player1Selection != "" {
                    selectedObject = objects.first(where: { $0.id == match.player1Selection })
                }
            } catch {
                print("Error fetching objects from cache: \(error)")
            }
        }
    }
}

#Preview("Active Game") {
    @Previewable var match = Match()
    ActiveGameView(match: match)
}
