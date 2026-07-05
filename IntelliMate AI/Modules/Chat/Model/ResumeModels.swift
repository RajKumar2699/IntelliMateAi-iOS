//
//  ResumeModels.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 04/07/26.
//

import Foundation

struct ResumeAnalysisResponse: Codable {
    let extractedText: String
    let overallScore: Int
    let atsScore: Int
    let matchedKeywords: [String]
    let missingKeywords: [String]
    let strengths: [String]
    let improvementPoints: [String]
    let jdAlignmentPoints: [String]
    let updatedResumeText: String?
    let reportText: String
    let pdfDownloadURL: String?

    enum CodingKeys: String, CodingKey {
        case extractedText = "extracted_text"
        case overallScore = "overall_score"
        case atsScore = "ats_score"
        case matchedKeywords = "matched_keywords"
        case missingKeywords = "missing_keywords"
        case strengths
        case improvementPoints = "improvement_points"
        case jdAlignmentPoints = "jd_alignment_points"
        case updatedResumeText = "updated_resume_text"
        case reportText = "report_text"
        case pdfDownloadURL = "pdf_download_url"
    }
}

struct SelectedResumeFile {
    let fileName: String
    let mimeType: String
    let data: Data
}
