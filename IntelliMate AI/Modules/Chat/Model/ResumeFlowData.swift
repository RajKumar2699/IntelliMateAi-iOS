//
//  ResumeFlowData.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 05/07/26.
//

import Foundation

struct ResumeFlowData {
    var selectedFile: SelectedResumeFile?
    var jobDescription: String = ""

    var originalAnalysis: ResumeAnalysisResponse?
    var improvedResponse: ResumeAnalysisResponse?
    var updatedAnalysis: ResumeAnalysisResponse?

    var updatedResumeText: String?
    var updatedPDFURL: String?
    var selectedTemplate: ResumeTemplateStyle = .minimal
}
