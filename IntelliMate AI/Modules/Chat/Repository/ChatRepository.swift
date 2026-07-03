//
//  ChatRepository.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import Foundation

protocol ChatRepository {
    func sendMessage(_ text: String) async throws -> ChatMessage
}
