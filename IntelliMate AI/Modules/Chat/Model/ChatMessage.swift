//
//  ChatMessage.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import Foundation

struct ChatMessage {
    let id: UUID
    let sender: Sender
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), sender: Sender, text: String, createdAt: Date = Date()) {
        self.id = id
        self.sender = sender
        self.text = text
        self.createdAt = createdAt
    }
}
