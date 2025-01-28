//
//  DeepSeekTestView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/27/25.
//

import EventSource
import SwiftUI

struct DeepSeekTestView: View {
    @State private var name1: String = ""
    @State private var name2: String = ""
    @State private var output: [String] = []
    @State private var fullOutput: String = ""
    
    var body: some View {
        VStack {
            TextField("Object1", text: $name1)
            TextField("Object2", text: $name2)
            Button("Action") {
                Task {
                    self.output = []
                    self.fullOutput = ""
                    let object1 = Object.object(named: name1)
                    let object2 = Object.object(named: name2)
                    let eventSource = EventSource()
                    let urlRequest = Network.deepSeekRequest(for: object1, vs: object2)
                    let dataTask = await eventSource.dataTask(for: urlRequest)

                    for await event in await dataTask.events() {
                        switch event {
                        case .open:
                            print("Connection was opened.")
                            output.append("Connection opened")
                        case .error(let error):
                            print("Received an error:", error.localizedDescription)
                            output.append("\(error)")
                        case .event(let event):
                            print("Received an event", event.data ?? "")
                            guard let data = event.data?.data(using: .utf8) else {
                                output.append("Fuck you no data")
                                continue
                            }
                            
                            do {
                                let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: data)
                                let strings = chunk.choices.compactMap { $0.delta.content }
                                output.append(contentsOf: strings)
                                fullOutput += strings.joined()
                            } catch {
                                output.append("Fuck you no chunk: \(error)")
                                output.append(event.data ?? "")
                                continue
                            }
                            
                            
//                            if let string = event.data { output.append(string) }
                        case .closed:
                            print("Connection was closed.")
                            output.append("Connection closed")
                        }
                    }
                }
            }
            ScrollView {
                Text(fullOutput)
                ForEach(output, id: \.self) { text in
                    Text(text)
                }
            }
        }
    }
}

#Preview {
    DeepSeekTestView()
}
