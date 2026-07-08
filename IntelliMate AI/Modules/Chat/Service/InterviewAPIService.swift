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

    private let baseURL = "http://192.168.1.10:8000" // replace with your Mac IP for real device

    func enrollCandidate(audioFileURL: URL, completion: @escaping (Result<VoiceEnrollmentResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/interview/enroll") else {
            completion(.failure(URLError(.badURL)))
            return
        }

        do {
            let audioData = try Data(contentsOf: audioFileURL)
            let boundary = UUID().uuidString

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            let filename = audioFileURL.lastPathComponent
            let mimeType = mimeTypeForAudioFile(filename: filename)
            request.httpBody = createMultipartBody(
                boundary: boundary,
                fieldName: "file",
                filename: filename,
                mimeType: mimeType,
                fileData: audioData
            )

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
                    let err = NSError(
                        domain: "InterviewAPIService",
                        code: http.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: body]
                    )
                    completion(.failure(err))
                    return
                }

                do {
                    let result = try JSONDecoder().decode(VoiceEnrollmentResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }.resume()

        } catch {
            completion(.failure(error))
        }
    }

    private func createMultipartBody(
        boundary: String,
        fieldName: String,
        filename: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private func mimeTypeForAudioFile(filename: String) -> String {
        let lower = filename.lowercased()
        if lower.hasSuffix(".wav") { return "audio/wav" }
        if lower.hasSuffix(".m4a") { return "audio/m4a" }
        if lower.hasSuffix(".mp3") { return "audio/mpeg" }
        if lower.hasSuffix(".webm") { return "audio/webm" }
        return "application/octet-stream"
    }
}
