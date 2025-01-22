//
//  User+Observable.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/22/25.
//

import FirebaseAuth
import SwiftUI

extension User: @retroactive ObservableObject { }

class ObservableUser: ObservableObject {
    @Published var user: User?
}
