//
//  Logging.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/24/25.
//

import FirebaseCrashlytics
import FirebaseCrashlyticsSwift

class Logger {
    static func log(_ error: Error, message: String = "") {
        print("\(message): \(error)")
        Crashlytics.crashlytics().record(error: error, userInfo: ["message": message])
    }
    
    static func log(_ message: String) {
        print(message)
        Crashlytics.crashlytics().log(message)
    }
}
