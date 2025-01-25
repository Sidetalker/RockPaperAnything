//
//  HomeView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/21/25.
//

import SwiftUI
import ImagePlayground

struct ObjectsView: View {
    @Environment(ObjectListener.self) private var objectListener
    
    @State private var isImagePlaygroundPresented = false
    @State private var prompt = ""
    @State private var isAddingItem = false
    
    var body: some View {
        NavigationView {
            List(objectListener.objects) {
                ObjectCell(object: $0)
            }
            .navigationTitle("Objects")
            .toolbar {
                Button("", systemImage: "plus") {
                    isAddingItem = true
                }
            }
        }.fullScreenCover(isPresented: $isAddingItem) {
            AddNewObjectView()
                .environment(\.modalMode, $isAddingItem)
        }
    }
}

struct ObjectCell: View {
    var object: Object
    
    var body: some View {
        HStack {
            ObjectImageView(object: object)
                .frame(width: 50)
            Text(object.name).padding(10)
        }
    }
}

#Preview("Objects List") {
    ObjectsView()
}
