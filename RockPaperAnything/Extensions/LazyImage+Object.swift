//
//  LazyImage+Object.swift
//  RockPaperAnything
//
//  Created by Kevin Sullivan on 1/25/25.
//

import NukeUI
import SwiftUI

extension LazyImage {
    init(object: Object,
         transaction: Transaction = Transaction(animation: nil),
         @ViewBuilder content: @escaping (LazyImageState) -> Content) {
        self.init(url: object.downloadUrl, transaction: transaction, content: content)
    }
}
