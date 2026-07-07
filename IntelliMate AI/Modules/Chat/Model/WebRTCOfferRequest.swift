//
//  WebRTCOfferRequest.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 07/07/26.
//


import Foundation

struct WebRTCOfferRequest: Encodable {
    let sdp: String
    let type: String
}