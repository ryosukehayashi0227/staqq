//
//  Item.swift
//  Staqq
//
//  Created by Hayashi Ryosuke on 2026/01/13.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
