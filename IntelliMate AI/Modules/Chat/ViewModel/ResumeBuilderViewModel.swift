//
//  ResumeBuilderViewModel.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 04/07/26.
//


import Foundation

@MainActor
final class ResumeBuilderViewModel {

    private let repository: ResumeRepository
    private(set) var flowData = ResumeFlowData()

    var onLoadingChanged: ((Bool) -> Void)?
    var onOriginalAnalysisReady: ((ResumeAnalysisResponse) -> Void)?
    var onImprovedResumeReady: ((ResumeAnalysisResponse) -> Void)?
    var onUpdatedAnalysisReady: ((ResumeAnalysisResponse) -> Void)?
    var onPDFDownloaded: ((URL) -> Void)?
    var onError: ((String) -> Void)?

    init(repository: ResumeRepository) {
        self.repository = repository
    }

    func setSelectedFile(_ file: SelectedResumeFile) {
        flowData.selectedFile = file
    }

    func setJobDescription(_ text: String) {
        flowData.jobDescription = text
    }

    func analyzeOriginalResume() {
        guard let file = flowData.selectedFile else {
            onError?("Please upload a resume first.")
            return
        }

        onLoadingChanged?(true)

        Task {
            do {
                let response = try await repository.analyzeOriginalResume(
                    file: file,
                    jobDescription: flowData.jobDescription
                )
                flowData.originalAnalysis = response
                onLoadingChanged?(false)
                onOriginalAnalysisReady?(response)
            } catch {
                onLoadingChanged?(false)
                onError?(error.localizedDescription)
            }
        }
    }

    func improveResume() {
        guard let file = flowData.selectedFile else {
            onError?("Please upload a resume first.")
            return
        }

        onLoadingChanged?(true)

        Task {
            do {
                let response = try await repository.improveResume(
                    file: file,
                    jobDescription: flowData.jobDescription
                )
                flowData.improvedResponse = response
                flowData.updatedResumeText = response.updatedResumeText
                flowData.updatedPDFURL = response.pdfDownloadURL
                onLoadingChanged?(false)
                onImprovedResumeReady?(response)
            } catch {
                onLoadingChanged?(false)
                onError?(error.localizedDescription)
            }
        }
    }

    func analyzeUpdatedResume() {
        guard let updatedResumeText = flowData.updatedResumeText,
              !updatedResumeText.isEmpty else {
            onError?("Updated resume not available.")
            return
        }

        onLoadingChanged?(true)

        Task {
            do {
                let response = try await repository.analyzeUpdatedResume(
                    updatedResumeText: updatedResumeText,
                    jobDescription: flowData.jobDescription
                )
                flowData.updatedAnalysis = response
                onLoadingChanged?(false)
                onUpdatedAnalysisReady?(response)
            } catch {
                onLoadingChanged?(false)
                onError?(error.localizedDescription)
            }
        }
    }

    func downloadUpdatedPDF() {
        guard let pdfPath = flowData.updatedPDFURL, !pdfPath.isEmpty else {
            onError?("Updated PDF not available.")
            return
        }

        onLoadingChanged?(true)

        Task {
            do {
                let localURL = try await repository.downloadPDF(from: pdfPath)
                onLoadingChanged?(false)
                onPDFDownloaded?(localURL)
            } catch {
                onLoadingChanged?(false)
                onError?(error.localizedDescription)
            }
        }
    }

    func setSelectedTemplate(_ template: ResumeTemplateStyle) {
        flowData.selectedTemplate = template
    }

    /// Generates a PDF for the current updatedResumeText using the given
    /// (or previously selected) template.
    ///
    /// `completion` lets the caller distinguish *why* it asked for a PDF —
    /// e.g. to preview it vs. to share/save it — without both actions
    /// ending up wired to the same onPDFDownloaded closure and doing the
    /// same thing. onPDFDownloaded still fires for any existing observers.
    func generatePDF(
        resumeText: String? = nil,
        template: ResumeTemplateStyle? = nil,
        completion: ((Result<URL, Error>) -> Void)? = nil
    ) {
        let textToRender = resumeText ?? flowData.updatedResumeText
        guard let textToRender, !textToRender.isEmpty else {
            let message = "Updated resume not available."
            onError?(message)
            completion?(.failure(NSError(
                domain: "ResumeBuilderViewModel",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: message]
            )))
            return
        }

        let templateToUse = template ?? flowData.selectedTemplate
        flowData.selectedTemplate = templateToUse

        onLoadingChanged?(true)

        Task {
            do {
                let localURL = try await ResumePDFGenerator.shared.generatePDFFile(
                    fromResumeText: textToRender,
                    template: templateToUse
                )
                flowData.updatedPDFURL = localURL.absoluteString
                onLoadingChanged?(false)
                onPDFDownloaded?(localURL)
                completion?(.success(localURL))
            } catch {
                onLoadingChanged?(false)
                let message = "Couldn't generate PDF: \(error.localizedDescription)"
                onError?(message)
                completion?(.failure(error))
            }
        }
    }
}
