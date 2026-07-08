//
//  BackendAPIService.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import Foundation

final class BackendAPIService {
    let baseURL: URL
    let session: URLSession

    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func createRealtimeSession(languageHint: String? = nil, voice: String? = nil) async throws -> RealtimeSessionResponse {
        let url = baseURL.appendingPathComponent("/api/v1/realtime/session")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RealtimeSessionRequest(languageHint: languageHint, voice: voice)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard 200..<300 ~= http.statusCode else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NSError(domain: "BackendAPIService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }

        return try JSONDecoder().decode(RealtimeSessionResponse.self, from: data)
    }
}
