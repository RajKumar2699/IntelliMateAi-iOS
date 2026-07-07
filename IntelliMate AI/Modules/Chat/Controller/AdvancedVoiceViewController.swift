//
//  AdvancedVoiceViewController.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 07/07/26.
//


import UIKit

final class AdvancedVoiceViewController: UIViewController {

    private let viewModel: AdvancedVoiceViewModel

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let orbView = OrbView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusContainer = UIView()
    private let statusLabel = UILabel()
    private let transcriptContainer = UIView()
    private let textView = UITextView()
    private let startButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)

    init(viewModel: AdvancedVoiceViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupUI()
        bindViewModel()
        applyInitialState()
    }

    private func setupAppearance() {
        title = "Voice Assistant"
        view.backgroundColor = .systemBackground
    }

    private func setupUI() {
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInsetAdjustmentBehavior = .automatic

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        titleLabel.text = "Talk to IntelliMate"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label

        subtitleLabel.text = "Speak naturally and get real-time AI responses."
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        orbView.translatesAutoresizingMaskIntoConstraints = false
        orbView.isUserInteractionEnabled = false
        orbView.setState(.idle)

        statusContainer.backgroundColor = .secondarySystemBackground
        statusContainer.layer.cornerRadius = 18

        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textColor = .label
        statusContainer.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: statusContainer.topAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -12),
            statusLabel.bottomAnchor.constraint(equalTo: statusContainer.bottomAnchor)
        ])

        transcriptContainer.backgroundColor = .secondarySystemBackground
        transcriptContainer.layer.cornerRadius = 20
        transcriptContainer.layer.borderWidth = 1
        transcriptContainer.layer.borderColor = UIColor.separator.cgColor

        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .label
        textView.text = "Your conversation transcript will appear here..."
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)

        transcriptContainer.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: transcriptContainer.topAnchor),
            textView.leadingAnchor.constraint(equalTo: transcriptContainer.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: transcriptContainer.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: transcriptContainer.bottomAnchor)
        ])

        startButton.setTitle("Start Talking", for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 16
        startButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)

        stopButton.setTitle("Stop", for: .normal)
        stopButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        stopButton.backgroundColor = .tertiarySystemBackground
        stopButton.setTitleColor(.label, for: .normal)
        stopButton.layer.cornerRadius = 16
        stopButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)

        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [startButton, stopButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 8

        let mainStack = UIStackView(arrangedSubviews: [
            headerStack,
            orbView,
            statusContainer,
            transcriptContainer,
            buttonStack
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

            orbView.heightAnchor.constraint(equalToConstant: 220),
            statusContainer.heightAnchor.constraint(equalToConstant: 44),
            transcriptContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 180),
            startButton.heightAnchor.constraint(equalToConstant: 54),
            stopButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.applyState(state)
            }
        }

        viewModel.onTranscript = { [weak self] text, role in
            DispatchQueue.main.async {
                guard let self else { return }
                let prefix = role ?? "assistant"
                let existing = self.textView.text == "Your conversation transcript will appear here..." ? "" : (self.textView.text ?? "")
                self.textView.text = existing.isEmpty ? "\(prefix): \(text)" : "\(existing)\n\(prefix): \(text)"
            }
        }

        viewModel.onError = { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusLabel.text = "Failed"
                let existing = self.textView.text ?? ""
                self.textView.text = existing.isEmpty ? "error: \(error)" : "\(existing)\nerror: \(error)"
                self.orbView.setState(.idle)
            }
        }
    }

    private func applyInitialState() {
        statusLabel.text = "Disconnected"
        orbView.setState(.idle)
        stopButton.isEnabled = false
    }

    private func applyState(_ state: VoiceConnectionState) {
        switch state {
        case .disconnected:
            statusLabel.text = "Disconnected"
            statusContainer.backgroundColor = .secondarySystemBackground
            orbView.setState(.idle)
            startButton.isEnabled = true
            stopButton.isEnabled = false

        case .connecting:
            statusLabel.text = "Connecting..."
            statusContainer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
            orbView.setState(.thinking)
            startButton.isEnabled = false
            stopButton.isEnabled = true

        case .connected:
            statusLabel.text = "Listening"
            statusContainer.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
            orbView.setState(.listening)
            startButton.isEnabled = false
            stopButton.isEnabled = true

        case .failed:
            statusLabel.text = "Connection Failed"
            statusContainer.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
            orbView.setState(.idle)
            startButton.isEnabled = true
            stopButton.isEnabled = false

        @unknown default:
            statusLabel.text = "Unknown"
            statusContainer.backgroundColor = .secondarySystemBackground
            orbView.setState(.idle)
            startButton.isEnabled = true
            stopButton.isEnabled = false
        }
    }

    @objc private func startTapped() {
        textView.text = "Your conversation transcript will appear here..."
        viewModel.startVoiceCall()
    }

    @objc private func stopTapped() {
        viewModel.stopVoiceCall()
        applyInitialState()
    }
}
