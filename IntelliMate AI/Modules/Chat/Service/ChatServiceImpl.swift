//
//  ChatServiceImpl.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import Foundation

final class ChatServiceImpl: ChatService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func sendMessage(_ request: ChatRequest) async throws -> ChatResponse {
        try await apiClient.request(
            endpoint: .chat,
            method: .post,
            body: request
        )
    }
}