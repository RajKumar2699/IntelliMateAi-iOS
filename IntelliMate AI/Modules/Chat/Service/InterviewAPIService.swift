//
//  InterviewAPIService.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import Foundation

final class InterviewAPIService {
    static let shared = InterviewAPIService()
    private init() {}

    private let baseURL = "http://10.83.230.123:8000"

    func enrollCandidate(
        audioFileURLs: [URL],
        completion: @escaping (Result<VoiceEnrollmentResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/interview/enroll") else {
            completion(.failure(URLError(.badURL)))
            return
        }

        guard audioFileURLs.count >= 3 else {
            completion(.failure(NSError(
                domain: "InterviewAPIService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Please provide at least 3 enrollment audio files"]
            )))
            return
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try createMultipartBody(
                boundary: boundary,
                fieldName: "files",
                fileURLs: audioFileURLs
            )
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data, let http = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            guard 200..<300 ~= http.statusCode else {
                let body = String(data: data, encoding: .utf8) ?? "Unknown server error"
                completion(.failure(NSError(
                    domain: "InterviewAPIService",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: body]
                )))
                return
            }

            do {
                let result = try JSONDecoder().decode(VoiceEnrollmentResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func createMultipartBody(
        boundary: String,
        fieldName: String,
        fileURLs: [URL]
    ) throws -> Data {
        var body = Data()

        for fileURL in fileURLs {
            let fileData = try Data(contentsOf: fileURL)
            let filename = fileURL.lastPathComponent
            let mimeType = mimeTypeForAudioFile(filename: filename)

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private func mimeTypeForAudioFile(filename: String) -> String {
        let lower = filename.lowercased()
        if lower.hasSuffix(".wav") { return "audio/wav" }
        if lower.hasSuffix(".caf") { return "audio/x-caf" }
        if lower.hasSuffix(".m4a") { return "audio/m4a" }
        if lower.hasSuffix(".mp3") { return "audio/mpeg" }
        return "application/octet-stream"
    }
}
