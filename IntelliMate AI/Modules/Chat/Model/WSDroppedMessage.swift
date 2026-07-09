//
//  WSDroppedMessage.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 09/07/26.
//


import Foundation

struct WSDroppedMessage: Codable {
    let type: String
    let reason: String
    let score: Double
}
