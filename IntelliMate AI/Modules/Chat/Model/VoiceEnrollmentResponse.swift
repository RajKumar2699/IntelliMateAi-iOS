//
//  VoiceEnrollmentResponse.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import Foundation

struct VoiceEnrollmentResponse: Codable {
    let profileId: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case message
    }
}
