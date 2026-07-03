//
//  ChatService.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import Foundation

protocol ChatService {
    func sendMessage(_ request: ChatRequest) async throws -> ChatResponse
}