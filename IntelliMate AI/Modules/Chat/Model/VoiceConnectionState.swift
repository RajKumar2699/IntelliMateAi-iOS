//
//  VoiceConnectionState.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 07/07/26.
//


import Foundation

enum VoiceConnectionState: String {
    case idle
    case connecting
    case connected
    case listening
    case processing
    case speaking
    case interrupted
    case disconnected
    case failed
}
