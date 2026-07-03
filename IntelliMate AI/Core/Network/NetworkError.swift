//
//  NetworkError.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidStatusCode(Int)
    case encodingError(Error)
    case decodingError(Error)
    case noInternet
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid response."
        case .invalidStatusCode(let code):
            return "Server returned status code \(code)."
        case .encodingError(let error):
            return "Encoding failed: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .noInternet:
            return "No internet connection."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
