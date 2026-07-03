//
//  ChatViewModel.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import Foundation

@MainActor
final class ChatViewModel {
    private let repository: any ChatRepository

    private(set) var messages: [ChatMessage] = []
    var onMessagesChanged: (() -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?

    init(repository: any ChatRepository) {
        self.repository = repository
    }

    func numberOfRows() -> Int {
        messages.count
    }

    func message(at index: Int) -> ChatMessage {
        messages[index]
    }

    func sendMessage(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let userMessage = ChatMessage(sender: .user, text: trimmedText)
        messages.append(userMessage)
        onMessagesChanged?()
        onLoadingChanged?(true)

        Task {
            do {
                let aiMessage = try await repository.sendMessage(trimmedText)
                messages.append(aiMessage)
                onLoadingChanged?(false)
                onMessagesChanged?()
            } catch {
                onLoadingChanged?(false)
                onError?(error.localizedDescription)
            }
        }
    }
}
