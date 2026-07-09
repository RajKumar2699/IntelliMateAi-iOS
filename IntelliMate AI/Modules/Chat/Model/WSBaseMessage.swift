//
//  WSBaseMessage.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 09/07/26.
//


import Foundation

struct WSBaseMessage: Codable {
    let type: String
}

struct WSSessionStarted: Codable {
    let type: String
    let sessionId: String
    let candidateProfileId: String

    enum CodingKeys: String, CodingKey {
        case type
        case sessionId = "session_id"
        case candidateProfileId = "candidate_profile_id"
    }
}

struct WSInterviewerRegistered: Codable {
    let type: String
    let interviewerProfileId: String
    let scoreVsCandidate: Double?

    enum CodingKeys: String, CodingKey {
        case type
        case interviewerProfileId = "interviewer_profile_id"
        case scoreVsCandidate = "score_vs_candidate"
    }
}

struct WSTranscriptMessage: Codable {
    let type: String
    let speaker: String
    let similarity: Double?
    let text: String
}

struct WSAnswerMessage: Codable {
    let type: String
    let question: String
    let answer: String
}

struct WSErrorMessage: Codable {
    let type: String
    let message: String
}
