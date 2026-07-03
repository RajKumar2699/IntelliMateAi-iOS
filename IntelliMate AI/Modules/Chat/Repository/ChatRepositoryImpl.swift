//
//  ChatRepositoryImpl.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


final class ChatRepositoryImpl: ChatRepository {
    private let service: ChatService

    init(service: ChatService) {
        self.service = service
    }

    func sendMessage(_ text: String) async throws -> ChatMessage {
        let request = ChatRequest(message: text)
        let response = try await service.sendMessage(request)
        return ChatMessage(sender: .ai, text: response.response)
    }
}
