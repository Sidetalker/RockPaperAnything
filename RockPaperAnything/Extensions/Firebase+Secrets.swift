//
//  Firebase+Secrets.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/27/25.
//

import FirebaseCore

extension FirebaseApp {
    static func configureWithSecrets() {
        let options = FirebaseOptions.defaultOptions()!
        options.apiKey = Secrets.firebaseApiKey
        self.configure(options: options)
    }
}
