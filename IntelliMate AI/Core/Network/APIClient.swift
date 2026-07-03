//
//  APIClient.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import Foundation

protocol APIClient {
    func request<T: Decodable, U: Encodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: U?
    ) async throws -> T
}
