//
//  AssistantEvent.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 07/07/26.
//


import Foundation

struct AssistantEvent: Decodable {
    let type: String
    let state: String?
    let role: String?
    let text: String?
}