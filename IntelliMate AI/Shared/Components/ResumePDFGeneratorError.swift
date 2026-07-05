//
//  ResumePDFGeneratorError.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 05/07/26.
//


import UIKit
import WebKit

enum ResumePDFGeneratorError: Error {
    case renderingFailed
}

enum ResumeTemplateStyle: String, CaseIterable {
    case modern
    case classic
    case minimal
    case executive

    var displayName: String {
        switch self {
        case .modern: return "Modern"
        case .classic: return "Classic"
        case .minimal: return "Minimal"
        case .executive: return "Executive"
        }
    }

    var subtitle: String {
        switch self {
        case .modern: return "Bold accent color, clean section bars"
        case .classic: return "Traditional serif, formal look"
        case .minimal: return "Understated, whitespace-first"
        case .executive: return "Dark header band, senior-level feel"
        }
    }

    fileprivate var css: String {
        switch self {
        case .modern: return Self.modernCSS
        case .classic: return Self.classicCSS
        case .minimal: return Self.minimalCSS
        case .executive: return Self.executiveCSS
        }
    }

    // MARK: - Modern

    private static let modernCSS = """
    @page { margin: 40px 46px; }
    * { box-sizing: border-box; }
    body {
        font-family: -apple-system, "Helvetica Neue", Arial, sans-serif;
        font-size: 15px;
        line-height: 1.62;
        color: #1c1c1e;
        margin: 0;
    }
    .resume { padding: 40px 46px; }
    b, strong { color: #0b3d91; font-weight: 700; }
    .name-line {
        font-size: 30px;
        font-weight: 800;
        color: #0b3d91;
        text-align: center;
        margin-bottom: 6px;
    }
    .contact-line {
        font-size: 13.5px;
        color: #4a4a4a;
        text-align: center;
        margin-bottom: 3px;
    }
    .section-heading {
        font-size: 17px;
        font-weight: 800;
        color: #0b3d91;
        text-transform: uppercase;
        letter-spacing: 0.7px;
        border-bottom: 2px solid #0b3d91;
        padding-bottom: 5px;
        margin-top: 22px;
        margin-bottom: 12px;
    }
    .line { margin-bottom: 8px; }
    .bullet {
        margin: 0 0 7px 8px;
        padding-left: 16px;
        text-indent: -16px;
    }
    a { color: #0b3d91; text-decoration: none; }
    """

    // MARK: - Classic

    private static let classicCSS = """
    @page { margin: 42px 48px; }
    * { box-sizing: border-box; }
    body {
        font-family: Georgia, "Times New Roman", serif;
        font-size: 14.5px;
        line-height: 1.65;
        color: #222222;
        margin: 0;
    }
    .resume { padding: 42px 48px; }
    b, strong { color: #000000; font-weight: 700; }
    .name-line {
        font-size: 28px;
        font-weight: 700;
        color: #000000;
        text-align: center;
        letter-spacing: 0.4px;
        margin-bottom: 6px;
    }
    .contact-line {
        font-size: 13px;
        color: #444444;
        text-align: center;
        margin-bottom: 3px;
    }
    .section-heading {
        font-size: 16px;
        font-weight: 700;
        color: #000000;
        text-transform: uppercase;
        letter-spacing: 1px;
        border-bottom: 1px solid #000000;
        padding-bottom: 4px;
        margin-top: 24px;
        margin-bottom: 12px;
        text-align: center;
    }
    .line { margin-bottom: 8px; }
    .bullet {
        margin: 0 0 7px 8px;
        padding-left: 16px;
        text-indent: -16px;
    }
    a { color: #000000; text-decoration: underline; }
    """

    // MARK: - Minimal

    private static let minimalCSS = """
    @page { margin: 38px 44px; }
    * { box-sizing: border-box; }
    body {
        font-family: -apple-system, "Helvetica Neue", Arial, sans-serif;
        font-size: 14.5px;
        line-height: 1.7;
        color: #2a2a2a;
        margin: 0;
        font-weight: 400;
    }
    .resume { padding: 38px 44px; }
    b, strong { color: #2a2a2a; font-weight: 600; }
    .name-line {
        font-size: 27px;
        font-weight: 500;
        letter-spacing: 0.8px;
        color: #2a2a2a;
        text-align: left;
        margin-bottom: 4px;
    }
    .contact-line {
        font-size: 13px;
        color: #757575;
        text-align: left;
        margin-bottom: 3px;
    }
    .section-heading {
        font-size: 14px;
        font-weight: 700;
        color: #7a7a7a;
        text-transform: uppercase;
        letter-spacing: 1.8px;
        border-bottom: none;
        margin-top: 24px;
        margin-bottom: 12px;
    }
    .line { margin-bottom: 8px; }
    .bullet {
        margin: 0 0 7px 6px;
        padding-left: 14px;
        text-indent: -14px;
    }
    a { color: #2a2a2a; text-decoration: underline; }
    """

    // MARK: - Executive

    private static let executiveCSS = """
    @page { margin: 0px; }
    * { box-sizing: border-box; }
    body {
        font-family: -apple-system, "Helvetica Neue", Arial, sans-serif;
        font-size: 15px;
        line-height: 1.6;
        color: #1c1c1e;
        margin: 0;
    }
    .resume { padding: 0 46px 40px 46px; }
    b, strong { color: #14213d; font-weight: 700; }
    .name-line {
        font-size: 30px;
        font-weight: 800;
        color: #ffffff;
        text-align: center;
        background-color: #14213d;
        padding: 30px 20px 8px 20px;
        margin: 0 -46px 4px -46px;
    }
    .contact-line {
        font-size: 13.5px;
        color: #d9dde5;
        text-align: center;
        background-color: #14213d;
        padding: 0 20px;
        margin: 0 -46px 0 -46px;
    }
    .contact-line:last-of-type { padding-bottom: 24px; }
    .section-heading {
        font-size: 16px;
        font-weight: 800;
        color: #14213d;
        text-transform: uppercase;
        letter-spacing: 0.6px;
        border-left: 4px solid #fca311;
        padding-left: 10px;
        margin-top: 24px;
        margin-bottom: 12px;
    }
    .line { margin-bottom: 8px; }
    .bullet {
        margin: 0 0 7px 8px;
        padding-left: 16px;
        text-indent: -16px;
    }
    a { color: #14213d; text-decoration: none; }
    """
}

@MainActor
final class ResumePDFGenerator {

    static let shared = ResumePDFGenerator()

    private static let knownHeadings = [
        "Professional Summary",
        "Key Highlights",
        "Core Technical Skills",
        "Professional Experience",
        "Key Projects",
        "Education",
        "Additional Information"
    ]

    /// Renders resumeText as a PDF. Safe to call concurrently: each call
    /// creates its own PDFRenderSession, so there is no shared webView or
    /// continuation state that a second in-flight call could overwrite.
    func generatePDF(fromResumeText resumeText: String, template: ResumeTemplateStyle) async throws -> Data {
        let html = Self.htmlDocument(from: resumeText, template: template)
        let session = PDFRenderSession()
        return try await session.render(html: html)
    }

    func generatePDFFile(
        fromResumeText resumeText: String,
        template: ResumeTemplateStyle,
        fileName: String = "updated_resume.pdf"
    ) async throws -> URL {
        let data = try await generatePDF(fromResumeText: resumeText, template: template)

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try data.write(to: destinationURL)
        return destinationURL
    }

    // MARK: - HTML construction

    private static func htmlDocument(from resumeText: String, template: ResumeTemplateStyle) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>\(template.css)</style>
        </head>
        <body>
        <div class="resume">
        \(htmlBody(from: resumeText))
        </div>
        </body>
        </html>
        """
    }

    private static func htmlBody(from resumeText: String) -> String {
        let lines = resumeText.components(separatedBy: .newlines)
        var html = ""
        var inHeaderBlock = true
        var isFirstLine = true

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            let normalized = normalizeForHeadingMatch(line)

            if let canonicalHeading = knownHeadings.first(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
                inHeaderBlock = false
                html += "<div class=\"section-heading\">\(canonicalHeading)</div>\n"
            } else if inHeaderBlock {
                let cssClass = isFirstLine ? "name-line" : "contact-line"
                html += "<div class=\"\(cssClass)\">\(line)</div>\n"
            } else if line.hasPrefix("•") || line.hasPrefix("-") {
                html += "<div class=\"bullet\">\(line)</div>\n"
            } else {
                html += "<div class=\"line\">\(line)</div>\n"
            }

            isFirstLine = false
        }

        return html
    }

    /// Strips whatever bold markup a heading line might carry — <b>/<strong>
    /// tags or leftover markdown asterisks — plus a trailing colon, before
    /// comparing against knownHeadings. Without this, a heading that comes
    /// through as "**Key Highlights**" or "Key Highlights:" silently fails
    /// to match and renders as plain body text instead of a styled heading.
    private static func normalizeForHeadingMatch(_ line: String) -> String {
        var result = line
        for tag in ["<b>", "</b>", "<strong>", "</strong>"] {
            result = result.replacingOccurrences(of: tag, with: "")
        }
        result = result.replacingOccurrences(of: "**", with: "")
        result = result.trimmingCharacters(in: .whitespaces)
        if result.hasSuffix(":") {
            result = String(result.dropLast())
        }
        return result.trimmingCharacters(in: .whitespaces)
    }
}

/// Owns exactly one WKWebView and one continuation for a single render
/// pass. Previously this state lived directly on the ResumePDFGenerator
/// singleton, so two overlapping calls (e.g. a double-tap on "Generate")
/// could overwrite each other's webView/continuation mid-render, causing
/// either a "continuation resumed more than once" crash or the wrong PDF
/// being delivered to the wrong caller. Creating a fresh instance per call
/// makes that impossible — there is nothing left to share.
@MainActor
private final class PDFRenderSession: NSObject, WKNavigationDelegate {

    private var webView: WKWebView?
    private var continuation: CheckedContinuation<Data, Error>?

    func render(html: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let webView = WKWebView(
                frame: CGRect(x: 0, y: 0, width: 816, height: 1056),
                configuration: WKWebViewConfiguration()
            )
            webView.navigationDelegate = self
            webView.isOpaque = false
            webView.backgroundColor = .white
            self.webView = webView

            Self.attachOffscreen(webView)
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    private static func attachOffscreen(_ webView: WKWebView) {
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first

        guard let window = windowScene?.windows.first(where: { $0.isKeyWindow }) ?? windowScene?.windows.first else {
            return
        }

        webView.isUserInteractionEnabled = false
        webView.alpha = 0.01
        window.insertSubview(webView, at: 0)
    }

    /// Guards against the delegate firing more than once for the same
    /// session (e.g. didFinish followed later by didFail) by nil-ing the
    /// continuation before resuming it.
    private func finish(_ result: Result<Data, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        switch result {
        case .success(let data): continuation.resume(returning: data)
        case .failure(let error): continuation.resume(throwing: error)
        }
        webView?.removeFromSuperview()
        webView = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.setNeedsLayout()
        webView.layoutIfNeeded()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)

            let config = WKPDFConfiguration()
            webView.createPDF(configuration: config) { [weak self] result in
                self?.finish(result)
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(.failure(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(.failure(error))
    }
}
