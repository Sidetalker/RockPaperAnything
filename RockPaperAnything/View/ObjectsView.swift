//
//  HomeView.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/21/25.
//

import SwiftUI
import ImagePlayground

struct ObjectsView: View {
    @State private var viewModel = ObjectViewModel()
    
    @State private var isImagePlaygroundPresented = false
    @State private var prompt = ""
    @State private var isAddingItem = false
    
    var body: some View {
        NavigationView {
            List(viewModel.objects) {
                ObjectCell(object: $0)
            }
            .navigationTitle("Objects")
            .toolbar {
                Button("", systemImage: "plus") {
                    isAddingItem = true
                }
            }
        }.fullScreenCover(isPresented: $isAddingItem) {
            AddNewObjectView(objects: viewModel.objects)
                .environment(\.modalMode, $isAddingItem)
        }.onAppear {
            viewModel.startListening()
        }
    }
}

struct ObjectCell: View {
    var object: Object
    
    var body: some View {
        HStack {
            ObjectImageView(object: object, size: 50)
            Text(object.name).padding(10)
        }
    }
}

#Preview("Objects List") {
    ObjectsView()
}
