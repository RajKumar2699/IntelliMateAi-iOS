//
//  VoiceRepository.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 06/07/26.
//


import Foundation

protocol VoiceRepository {
    func streamReply(message: String) -> AsyncThrowingStream<String, Error>
}

final class VoiceRepositoryImpl: VoiceRepository {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = "http://10.83.230.123:8000", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func streamReply(message: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(baseURL)/api/v1/voice/stream") else {
                        throw URLError(.badURL)
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let payload = VoiceStreamRequest(message: message)
                    request.httpBody = try JSONEncoder().encode(payload)

                    let (bytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          200...299 ~= httpResponse.statusCode else {
                        throw URLError(.badServerResponse)
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }

                        let jsonString = String(line.dropFirst(6))
                        guard let data = jsonString.data(using: .utf8) else { continue }

                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            let type = json["type"] as? String

                            if type == "text", let content = json["content"] as? String {
                                continuation.yield(content)
                            } else if type == "done" {
                                continuation.finish()
                                return
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
