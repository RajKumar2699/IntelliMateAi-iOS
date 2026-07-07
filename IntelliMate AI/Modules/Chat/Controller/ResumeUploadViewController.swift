//
//  ResumeUploadViewController.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 05/07/26.
//


import UIKit
import UniformTypeIdentifiers

final class ResumeUploadViewController: UIViewController {

    private let viewModel: ResumeBuilderViewModel

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentStack = UIStackView()

    private let titleLabel = UILabel()
    private let uploadButton = UIButton(type: .system)
    private let fileLabel = UILabel()

    private let jdLabel = UILabel()
    private let jdTextView = UITextView()

    private let atsCircleView = ATSCircleView()

    private let checkATSButton = UIButton(type: .system)
    private let improveResumeButton = UIButton(type: .system)

    private let loadingIndicator = UIActivityIndicatorView(style: .large)

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
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "Resume"

        setupScrollView()
        setupViews()
        setupLayout()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInsetAdjustmentBehavior = .automatic

        contentView.translatesAutoresizingMaskIntoConstraints = false

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 18
        contentStack.alignment = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func setupViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Upload Resume"
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textAlignment = .center

        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.setTitle("Upload Resume", for: .normal)
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.backgroundColor = .systemBlue
        uploadButton.layer.cornerRadius = 18
        uploadButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        uploadButton.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        uploadButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        fileLabel.translatesAutoresizingMaskIntoConstraints = false
        fileLabel.text = "No file selected"
        fileLabel.textColor = .secondaryLabel
        fileLabel.font = .systemFont(ofSize: 15, weight: .medium)
        fileLabel.numberOfLines = 2
        fileLabel.textAlignment = .center

        jdLabel.translatesAutoresizingMaskIntoConstraints = false
        jdLabel.text = "Job Description"
        jdLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        jdTextView.translatesAutoresizingMaskIntoConstraints = false
        jdTextView.layer.borderWidth = 1
        jdTextView.layer.borderColor = UIColor.systemGray4.cgColor
        jdTextView.layer.cornerRadius = 14
        jdTextView.font = .systemFont(ofSize: 15)
        jdTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        jdTextView.text = "Paste Job Description"
        jdTextView.textColor = .secondaryLabel
        jdTextView.delegate = self
        jdTextView.heightAnchor.constraint(equalToConstant: 150).isActive = true

        atsCircleView.translatesAutoresizingMaskIntoConstraints = false
        atsCircleView.update(score: 0)
        atsCircleView.heightAnchor.constraint(equalToConstant: 220).isActive = true

        checkATSButton.translatesAutoresizingMaskIntoConstraints = false
        checkATSButton.setTitle("Check ATS Score", for: .normal)
        checkATSButton.setTitleColor(.white, for: .normal)
        checkATSButton.backgroundColor = .systemGreen
        checkATSButton.layer.cornerRadius = 16
        checkATSButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        checkATSButton.addTarget(self, action: #selector(checkATSTapped), for: .touchUpInside)
        checkATSButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        improveResumeButton.translatesAutoresizingMaskIntoConstraints = false
        improveResumeButton.setTitle("Improve Resume", for: .normal)
        improveResumeButton.setTitleColor(.white, for: .normal)
        improveResumeButton.backgroundColor = .systemPurple
        improveResumeButton.layer.cornerRadius = 16
        improveResumeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        improveResumeButton.isEnabled = false
        improveResumeButton.alpha = 0.5
        improveResumeButton.addTarget(self, action: #selector(improveTapped), for: .touchUpInside)
        improveResumeButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true

        let atsContainer = UIView()
        atsContainer.translatesAutoresizingMaskIntoConstraints = false
        atsContainer.addSubview(atsCircleView)
        NSLayoutConstraint.activate([
            atsCircleView.centerXAnchor.constraint(equalTo: atsContainer.centerXAnchor),
            atsCircleView.topAnchor.constraint(equalTo: atsContainer.topAnchor),
            atsCircleView.bottomAnchor.constraint(equalTo: atsContainer.bottomAnchor),
            atsCircleView.widthAnchor.constraint(equalToConstant: 220)
        ])

        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(uploadButton)
        contentStack.addArrangedSubview(fileLabel)
        contentStack.addArrangedSubview(jdLabel)
        contentStack.addArrangedSubview(jdTextView)
        contentStack.addArrangedSubview(atsContainer)
        contentStack.addArrangedSubview(checkATSButton)
        contentStack.addArrangedSubview(improveResumeButton)

        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupLayout() {
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        fileLabel.setContentHuggingPriority(.required, for: .vertical)
        jdLabel.setContentHuggingPriority(.required, for: .vertical)
    }

    private func bindViewModel() {
        viewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self else { return }
            if isLoading {
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
            }
            self.checkATSButton.isEnabled = !isLoading
        }

        viewModel.onOriginalAnalysisReady = { [weak self] response in
            self?.atsCircleView.update(score: response.atsScore)
            self?.improveResumeButton.isEnabled = true
            self?.improveResumeButton.alpha = 1.0
        }

        viewModel.onError = { [weak self] message in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }

    @objc private func uploadTapped() {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.pdf, .plainText, UTType(filenameExtension: "docx") ?? .data],
            asCopy: true
        )
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func checkATSTapped() {
        let jdText = jdTextView.textColor == .secondaryLabel ? "" : (jdTextView.text ?? "")
        viewModel.setJobDescription(jdText)
        viewModel.analyzeOriginalResume()
    }

    @objc private func improveTapped() {
        let jdText = jdTextView.textColor == .secondaryLabel ? "" : (jdTextView.text ?? "")
        viewModel.setJobDescription(jdText)
        let vc = ResumeImproveViewController(viewModel: viewModel)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "pdf":
            return "application/pdf"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "txt":
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
}

extension ResumeUploadViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            let file = SelectedResumeFile(
                fileName: url.lastPathComponent,
                mimeType: mimeType(for: url.pathExtension),
                data: data
            )

            viewModel.setSelectedFile(file)
            fileLabel.text = url.lastPathComponent
            fileLabel.textColor = .label
            atsCircleView.update(score: 0)
            improveResumeButton.isEnabled = false
            improveResumeButton.alpha = 0.5
        } catch {
            fileLabel.text = "Failed to read selected file"
            fileLabel.textColor = .systemRed
        }
    }
}

extension ResumeUploadViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == jdTextView && textView.textColor == .secondaryLabel {
            textView.text = nil
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == jdTextView &&
            textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Paste Job Description"
            textView.textColor = .secondaryLabel
        }
    }
}
