//
//  URLSessionAPIClient.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import Foundation

final class URLSessionAPIClient: APIClient {
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    func request<T: Decodable, U: Encodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: U? = nil
    ) async throws -> T {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        APIConstants.defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw NetworkError.encodingError(error)
            }
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.invalidStatusCode(httpResponse.statusCode)
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        } catch let urlError as URLError {
            if urlError.code == .notConnectedToInternet {
                throw NetworkError.noInternet
            }
            throw NetworkError.unknown(urlError)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}