//
//  APIEndpoint.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import Foundation

enum APIEndpoint {
    case chat
}

extension APIEndpoint {
    var path: String {
        switch self {
        case .chat:
            return "/chat"
        }
    }
}

extension APIEndpoint {
    var url: URL? {
        URL(string: APIConstants.baseURL + APIConstants.apiVersion + path)
    }
}
