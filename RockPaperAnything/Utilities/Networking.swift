//
//  Networking.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/27/25.
//

import UIKit
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
    
    static func generateImage(for objectName: String) async -> UIImage? {
        let imageGenUrl = URL(string: "https://api.getimg.ai/v1/flux-schnell/text-to-image")!
        let prompt = 
"""
A highly detailed and slightly stylized yet realistic depiction of a \(objectName), blending clean, modern design with a subtle cartoonish aesthetic. 
The object is centered on a softly lit background, with smooth lighting and gentle shadows to emphasize depth. 
The background fits the vibe and theme of the featured objected but is slightly blurred, muted, and understated. 
The style is sleek, polished, and vibrant, inspired by Apple's design language, but with a playful and slightly exaggerated touch. 
Use creative and dynamic colors, textures, and shapes while maintaining a high-resolution, semi-realistic quality.
"""
        
        let bodyJson: [String: Any] = [
            "prompt": prompt
        ]
        
        let bodyData = try? JSONSerialization.data(withJSONObject: bodyJson)
        var urlRequest = URLRequest(url: imageGenUrl)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = bodyData
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(Secrets.getimgApiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let base64String = json["image"] as? String,
                  let imageData = Data(base64Encoded: base64String) else {
                return nil
            }
            
            return UIImage(data: imageData)
        } catch {
            print("Error generating image: \(error)")
            return nil
        }
    }
}
