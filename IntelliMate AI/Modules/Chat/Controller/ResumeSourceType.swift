//
//  ResumeSourceType.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 06/07/26.
//


import UIKit

enum ResumeSourceType: String, CaseIterable {
    case original = "Original"
    case tailored = "ATS-Tailored"
}


final class ResumeGenerationPickerViewController: UIViewController {

    private let viewModel: ResumeBuilderViewModel
    var onGenerated: ((URL) -> Void)?

    private let typeLabel = UILabel()
    private let typeSegmented = UISegmentedControl(items: ResumeSourceType.allCases.map { $0.rawValue })

    private let templateLabel = UILabel()
    private let templateSegmented = UISegmentedControl(items: ResumeTemplateStyle.allCases.map { $0.displayName })
    private let templateSubtitleLabel = UILabel()

    private let generateButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    init(viewModel: ResumeBuilderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Generate resume"
        setupUI()
        selectionChanged()
    }

    private func setupUI() {
        typeLabel.text = "Resume text"
        typeLabel.font = .preferredFont(forTextStyle: .headline)
        typeSegmented.selectedSegmentIndex = 1 // default to tailored, the common case
        typeSegmented.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)

        templateLabel.text = "Template"
        templateLabel.font = .preferredFont(forTextStyle: .headline)
        templateSegmented.selectedSegmentIndex = 0
        templateSegmented.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)

        templateSubtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        templateSubtitleLabel.textColor = .secondaryLabel
        templateSubtitleLabel.numberOfLines = 0

        generateButton.setTitle("Generate", for: .normal)
        generateButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            typeLabel, typeSegmented,
            templateLabel, templateSegmented, templateSubtitleLabel,
            generateButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(24, after: typeSegmented)
        stack.setCustomSpacing(28, after: templateSubtitleLabel)

        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            activityIndicator.centerXAnchor.constraint(equalTo: generateButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: generateButton.bottomAnchor, constant: 24),
        ])
    }

    @objc private func selectionChanged() {
        let selectedTemplate = ResumeTemplateStyle.allCases[templateSegmented.selectedSegmentIndex]
        templateSubtitleLabel.text = selectedTemplate.subtitle

        let sourceType = ResumeSourceType.allCases[typeSegmented.selectedSegmentIndex]
        generateButton.isEnabled = !resumeText(for: sourceType).isEmpty
    }

    private func resumeText(for type: ResumeSourceType) -> String {
        switch type {
        case .original:
            return viewModel.flowData.originalAnalysis?.extractedText ?? ""
        case .tailored:
            return viewModel.flowData.updatedResumeText ?? ""
        }
    }

    @objc private func generateTapped() {
        let sourceType = ResumeSourceType.allCases[typeSegmented.selectedSegmentIndex]
        let template = ResumeTemplateStyle.allCases[templateSegmented.selectedSegmentIndex]
        let text = resumeText(for: sourceType)

        guard !text.isEmpty else { return }

        generateButton.isEnabled = false
        activityIndicator.startAnimating()

        viewModel.generatePDF(resumeText: text, template: template) { [weak self] result in
            self?.activityIndicator.stopAnimating()
            self?.generateButton.isEnabled = true
            switch result {
            case .success(let url):
                self?.onGenerated?(url)
            case .failure(let error):
                self?.showError(error)
            }
        }
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Couldn't generate resume",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
