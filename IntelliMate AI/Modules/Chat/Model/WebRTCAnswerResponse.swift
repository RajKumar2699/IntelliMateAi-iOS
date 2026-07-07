//
//  WebRTCAnswerResponse.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 07/07/26.
//


import Foundation

struct WebRTCAnswerResponse: Decodable {
    let session_id: String
    let sdp: String
    let type: String
}
