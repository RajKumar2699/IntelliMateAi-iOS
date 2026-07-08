//
//  RealtimeSessionRequest.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import Foundation

struct RealtimeSessionRequest: Encodable {
    let languageHint: String?
    let voice: String?

    enum CodingKeys: String, CodingKey {
        case languageHint = "language_hint"
        case voice
    }
}

struct RealtimeSessionResponse: Decodable {
    let clientSecret: String
    let expiresAt: Int?
    let sessionId: String?
    let model: String
    let voice: String?

    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case expiresAt = "expires_at"
        case sessionId = "session_id"
        case model
        case voice
    }
}