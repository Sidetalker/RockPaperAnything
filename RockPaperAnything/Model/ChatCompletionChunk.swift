//
//  ChatCompletionChunk.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/27/25.
//

import Foundation

struct ChatCompletionChunk: Codable {
    let choices: [Choice]
    let created: Int
    let id: String
    let model: String
    let object: String
    let systemFingerprint: String

    enum CodingKeys: String, CodingKey {
        case choices, created, id, model, object
        case systemFingerprint = "system_fingerprint"
    }
}

struct Choice: Codable {
    let delta: Delta
    let finishReason: String?
    let index: Int
    let logprobs: String?

    enum CodingKeys: String, CodingKey {
        case delta
        case finishReason = "finish_reason"
        case index
        case logprobs
    }
}

struct Delta: Codable {
    let content: String?
}
