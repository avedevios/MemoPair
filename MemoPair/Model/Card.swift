//
//  Card.swift
//  MemoPair
//
//  Created by Anton Averianov on 2025-04-14.
//

import Foundation

struct Card: Equatable {
    let id: UUID = UUID()
    let content: String
    let pairID: Int
    var isMatched: Bool = false
}
