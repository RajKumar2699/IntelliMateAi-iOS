//
//  ResumeRepository.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 04/07/26.
//


import Foundation

protocol ResumeRepository {
    func analyzeOriginalResume(
        file: SelectedResumeFile,
        jobDescription: String
    ) async throws -> ResumeAnalysisResponse

    func improveResume(
        file: SelectedResumeFile,
        jobDescription: String
    ) async throws -> ResumeAnalysisResponse

    func analyzeUpdatedResume(
        updatedResumeText: String,
        jobDescription: String
    ) async throws -> ResumeAnalysisResponse

    func downloadPDF(from path: String) async throws -> URL
}

final class ResumeRepositoryImpl: ResumeRepository {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = "http://127.0.0.1:8000", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func analyzeOriginalResume(
        file: SelectedResumeFile,
        jobDescription: String
    ) async throws -> ResumeAnalysisResponse {
        return try await uploadResume(
            endpoint: "/api/v1/resume/analyze",
            file: file,
            jobDescription: jobDescription
        )
    }

    func improveResume(
        file: SelectedResumeFile,
        jobDescription: String
    ) async throws -> ResumeAnalysisResponse {
        return try await uploadResume(
            endpoint: "/api/v1/resume/analyze",
            file: file,
            jobDescription: jobDescription
        )
    }

    func analyzeUpdatedResume(
        updatedResumeText: String,
        jobDescription: String
    ) async throws -> ResumeAnalysisResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/resume/analyze-updated") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let payload = UpdatedResumeAnalysisRequest(
            updatedResumeText: updatedResumeText,
            jobDescription: jobDescription
        )

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw NSError(
                domain: "ResumeAnalyzeUpdatedAPI",
                code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Unknown server error"
                ]
            )
        }

        return try JSONDecoder().decode(ResumeAnalysisResponse.self, from: data)
    }
    
    func downloadPDF(from path: String) async throws -> URL {
        let fullPath: String
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            fullPath = path
        } else {
            fullPath = "\(baseURL)\(path)"
        }

        guard let url = URL(string: fullPath) else {
            throw URLError(.badURL)
        }

        let (tempURL, response) = try await session.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = url.lastPathComponent.isEmpty ? "updated_resume.pdf" : url.lastPathComponent
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: tempURL, to: destinationURL)
        return destinationURL
    }

    private func uploadResume(
        endpoint: String,
        file: SelectedResumeFile,
        jobDescription: String
    ) async throws -> ResumeAnalysisResponse {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }

        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = createMultipartBody(
            boundary: boundary,
            file: file,
            jobDescription: jobDescription
        )

        let (data, response) = try await session.upload(for: request, from: body)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw NSError(
                domain: "ResumeUploadAPI",
                code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Unknown server error"
                ]
            )
        }

        return try JSONDecoder().decode(ResumeAnalysisResponse.self, from: data)
    }

    private func createMultipartBody(
        boundary: String,
        file: SelectedResumeFile,
        jobDescription: String
    ) -> Data {
        var body = Data()

        if !jobDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"job_description\"\r\n\r\n")
            body.appendString("\(jobDescription)\r\n")
        }

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(file.fileName)\"\r\n")
        body.appendString("Content-Type: \(file.mimeType)\r\n\r\n")
        body.append(file.data)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")

        return body
    }
}

struct UpdatedResumeAnalysisRequest: Codable {
    let updatedResumeText: String
    let jobDescription: String

    enum CodingKeys: String, CodingKey {
        case updatedResumeText = "updated_resume_text"
        case jobDescription = "job_description"
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
