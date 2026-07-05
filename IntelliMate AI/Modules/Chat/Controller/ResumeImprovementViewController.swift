//
//  ResumeImprovementViewController.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 05/07/26.
//



import UIKit

final class ResumeImproveViewController: UIViewController {

    private let viewModel: ResumeBuilderViewModel

    private let jobDescriptionLabel = UILabel()
    private let jobDescriptionTextView = UITextView()

    private let updatedATSView = ATSCircleView()
    private let improvedResumeTextView = UITextView()

    private let generateButton = UIButton(type: .system)
    private let checkUpdatedATSButton = UIButton(type: .system)
    private let previewButton = UIButton(type: .system)
    private let downloadButton = UIButton(type: .system)

    init(viewModel: ResumeBuilderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        jobDescriptionTextView.text = viewModel.flowData.jobDescription
    }

    private func setupUI() {
        title = "Improve Resume"
        view.backgroundColor = .systemBackground

        jobDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        jobDescriptionLabel.text = "Job Description"
        jobDescriptionLabel.font = .systemFont(ofSize: 24, weight: .bold)

        jobDescriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        jobDescriptionTextView.layer.borderWidth = 1
        jobDescriptionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        jobDescriptionTextView.layer.cornerRadius = 16
        jobDescriptionTextView.font = .systemFont(ofSize: 16)
        jobDescriptionTextView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)

        updatedATSView.translatesAutoresizingMaskIntoConstraints = false
        updatedATSView.update(score: 0)

        improvedResumeTextView.translatesAutoresizingMaskIntoConstraints = false
        improvedResumeTextView.layer.borderWidth = 1
        improvedResumeTextView.layer.borderColor = UIColor.systemGray5.cgColor
        improvedResumeTextView.layer.cornerRadius = 16
        improvedResumeTextView.font = .systemFont(ofSize: 15)
        improvedResumeTextView.isEditable = false

        generateButton.translatesAutoresizingMaskIntoConstraints = false
        generateButton.setTitle("Generate Resume", for: .normal)
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.backgroundColor = .systemBlue
        generateButton.layer.cornerRadius = 16
        generateButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        generateButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)

        checkUpdatedATSButton.translatesAutoresizingMaskIntoConstraints = false
        checkUpdatedATSButton.setTitle("Check Updated ATS Score", for: .normal)
        checkUpdatedATSButton.setTitleColor(.white, for: .normal)
        checkUpdatedATSButton.backgroundColor = .systemPink
        checkUpdatedATSButton.layer.cornerRadius = 16
        checkUpdatedATSButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        checkUpdatedATSButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        checkUpdatedATSButton.isHidden = true
        checkUpdatedATSButton.addTarget(self, action: #selector(checkUpdatedATSTapped), for: .touchUpInside)

        previewButton.translatesAutoresizingMaskIntoConstraints = false
        previewButton.setTitle("Preview Updated Resume", for: .normal)
        previewButton.setTitleColor(.white, for: .normal)
        previewButton.backgroundColor = .systemPurple
        previewButton.layer.cornerRadius = 16
        previewButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        previewButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        previewButton.isHidden = true
        previewButton.addTarget(self, action: #selector(previewTapped), for: .touchUpInside)

        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.setTitle("Download PDF", for: .normal)
        downloadButton.setTitleColor(.white, for: .normal)
        downloadButton.backgroundColor = .systemGreen
        downloadButton.layer.cornerRadius = 16
        downloadButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        downloadButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        downloadButton.isHidden = true
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)

        view.addSubview(jobDescriptionLabel)
        view.addSubview(jobDescriptionTextView)
        view.addSubview(updatedATSView)
        view.addSubview(improvedResumeTextView)
        view.addSubview(generateButton)
        view.addSubview(checkUpdatedATSButton)
        view.addSubview(previewButton)
        view.addSubview(downloadButton)

        NSLayoutConstraint.activate([
            jobDescriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            jobDescriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            jobDescriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            jobDescriptionTextView.topAnchor.constraint(equalTo: jobDescriptionLabel.bottomAnchor, constant: 12),
            jobDescriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            jobDescriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            jobDescriptionTextView.heightAnchor.constraint(equalToConstant: 150),

            generateButton.topAnchor.constraint(equalTo: jobDescriptionTextView.bottomAnchor, constant: 18),
            generateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            generateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            updatedATSView.topAnchor.constraint(equalTo: generateButton.bottomAnchor, constant: 20),
            updatedATSView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            updatedATSView.widthAnchor.constraint(equalToConstant: 200),
            updatedATSView.heightAnchor.constraint(equalToConstant: 200),

            improvedResumeTextView.topAnchor.constraint(equalTo: updatedATSView.bottomAnchor, constant: 18),
            improvedResumeTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            improvedResumeTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            improvedResumeTextView.bottomAnchor.constraint(equalTo: checkUpdatedATSButton.topAnchor, constant: -18),

            checkUpdatedATSButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            checkUpdatedATSButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            checkUpdatedATSButton.bottomAnchor.constraint(equalTo: previewButton.topAnchor, constant: -12),

            previewButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            previewButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            previewButton.bottomAnchor.constraint(equalTo: downloadButton.topAnchor, constant: -12),

            downloadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            downloadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            downloadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func bindViewModel() {
        viewModel.onImprovedResumeReady = { [weak self] response in
            self?.improvedResumeTextView.text = response.updatedResumeText ?? response.reportText
            let hasResumeText = !(response.updatedResumeText ?? "").isEmpty
            self?.previewButton.isHidden = !hasResumeText
            self?.downloadButton.isHidden = !hasResumeText
            self?.checkUpdatedATSButton.isHidden = !hasResumeText
        }

        viewModel.onUpdatedAnalysisReady = { [weak self] response in
            self?.updatedATSView.update(score: response.atsScore)
        }

        viewModel.onError = { [weak self] message in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }

    @objc private func generateTapped() {
        viewModel.setJobDescription(jobDescriptionTextView.text ?? "")
        viewModel.improveResume()
    }

    @objc private func checkUpdatedATSTapped() {
        viewModel.setJobDescription(jobDescriptionTextView.text ?? "")
        viewModel.analyzeUpdatedResume()
    }

    @objc private func previewTapped() {
        presentTemplatePicker { [weak self] style in
            self?.viewModel.generatePDF(template: style) { [weak self] result in
                switch result {
                case .success(let url):
                    self?.pushPreview(for: url)
                case .failure:
                    break
                }
            }
        }
    }

    @objc private func downloadTapped() {
        presentTemplatePicker { [weak self] style in
            self?.viewModel.generatePDF(template: style) { [weak self] result in
                switch result {
                case .success(let url):
                    self?.presentShareSheet(for: url)
                case .failure:
                    break
                }
            }
        }
    }

    private func presentShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = downloadButton
            popover.sourceRect = downloadButton.bounds
        }
        present(activityVC, animated: true)
    }

    private func pushPreview(for url: URL) {
        let vc = ResumePreviewViewController(fileURL: url)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func presentTemplatePicker(completion: @escaping (ResumeTemplateStyle) -> Void) {
        let sheet = UIAlertController(
            title: "Choose Resume Style",
            message: "Same content, different design.",
            preferredStyle: .actionSheet
        )

        for style in ResumeTemplateStyle.allCases {
            let action = UIAlertAction(
                title: "\(style.displayName) — \(style.subtitle)",
                style: .default
            ) { _ in
                completion(style)
            }
            sheet.addAction(action)
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 80, width: 0, height: 0)
        }

        present(sheet, animated: true)
    }
}
