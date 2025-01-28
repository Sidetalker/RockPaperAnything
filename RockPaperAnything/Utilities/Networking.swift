//
//  Networking.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/27/25.
//

import Foundation

class Network {
    static func deepSeekRequest(for object1: Object, vs object2: Object) -> URLRequest {
        let deepSeekUrl = URL(string: "https://api.deepseek.com/chat/completions")!
        let systemPrompt =
"""
Input: 'Object1 vs Object2'.
Output: 'Winner|Reason'.
Example: 'Rock vs Scissors' → 'Rock|Rock crushes scissors decisively.'
Rules:
- Keep responses brief, creative, and imaginative.
- Highlight unique strengths of the winner.
- Add humor or dramatic flair.
"""
        let bodyJson: [String: Any] = [
            "messages": [
                [
                    "content": systemPrompt,
                    "role": "system"
                ],
                [
                    "content": "\(object1.name) vs \(object2.name)",
                    "role": "user"
                ]
            ],
            "model": "deepseek-chat",
            "frequency_penalty": 0,
            "max_tokens": 2048,
            "presence_penalty": 0,
            "response_format": [
                "type": "text"
            ],
            "stream": true,
            "temperature": 0.6
        ]
        let bodyData = try? JSONSerialization.data(withJSONObject: bodyJson)
        var urlRequest = URLRequest(url: deepSeekUrl)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = bodyData
        urlRequest.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(Secrets.deepseekApiKey)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
}
