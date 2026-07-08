//
//  FallbackTranscriptionRequest.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import Foundation

struct FallbackTranscriptionRequest: Encodable {
    let audioBase64: String
    let mimeType: String
    let languageCode: String?

    enum CodingKeys: String, CodingKey {
        case audioBase64 = "audio_base64"
        case mimeType = "mime_type"
        case languageCode = "language_code"
    }
}

struct FallbackTranscriptionResponse: Decodable {
    let transcript: String
    let languageCode: String?

    enum CodingKeys: String, CodingKey {
        case transcript
        case languageCode = "language_code"
    }
}

extension BackendAPIService {
    func fallbackTranscribe(audioData: Data, languageCode: String? = "unknown") async throws -> FallbackTranscriptionResponse {
        let url = baseURL.appendingPathComponent("/api/v1/fallback/transcribe")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = FallbackTranscriptionRequest(
            audioBase64: audioData.base64EncodedString(),
            mimeType: "audio/wav",
            languageCode: languageCode
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendAPIService", code: -10, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard 200..<300 ~= http.statusCode else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown fallback error"
            throw NSError(domain: "BackendAPIService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
        }

        return try JSONDecoder().decode(FallbackTranscriptionResponse.self, from: data)
    }
}
