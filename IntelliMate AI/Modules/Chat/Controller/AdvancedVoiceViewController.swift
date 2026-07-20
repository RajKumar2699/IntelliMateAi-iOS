//
//  AdvancedVoiceViewController.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 07/07/26.
//


import UIKit

final class AdvancedVoiceViewController: UIViewController {

    private let viewModel: AdvancedVoiceViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerContainer = UIView()

    private var speakerBarButtonItem: UIBarButtonItem!
    private var micBarButtonItem: UIBarButtonItem!
    private let orbView = OrbView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusContainer = UIView()
    private let statusDot = UIView()
    private let statusLabel = UILabel()

    private let emptyStateLabel = UILabel()
    private var messages: [VoiceChatMessage] = []

    // MARK: Fixed bottom bar (only these two buttons never scroll)
    private let bottomBar = UIView()
    private let startButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)

    private var isSpeakerMuted = false
    private var isMicMuted = false

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
        setupNavigationBar()
        setupHeaderContainer()
        setupTableView()
        setupBottomBar()
        setupLayout()
        bindViewModel()
        applyInitialState()
        updateSpeakerUI()
        updateMicUI()
        updateEmptyState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeaderToFit()
    }

    // MARK: - Setup

    private func setupAppearance() {
        title = "Voice Assistant"
        view.backgroundColor = .systemBackground
    }

    private func setupNavigationBar() {
        let clearButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clearChatTapped)
        )
        clearButton.tintColor = .systemRed
        clearButton.accessibilityLabel = "Clear Chat"
        navigationItem.rightBarButtonItem = clearButton

        speakerBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "speaker.wave.2.fill"),
            style: .plain,
            target: self,
            action: #selector(didTapSpeaker)
        )
        speakerBarButtonItem.accessibilityLabel = "Speaker"

        micBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "mic.fill"),
            style: .plain,
            target: self,
            action: #selector(didTapMic)
        )
        micBarButtonItem.accessibilityLabel = "Microphone"

        navigationItem.leftBarButtonItems = [micBarButtonItem, speakerBarButtonItem]
    }

    private func setupHeaderContainer() {
        titleLabel.text = "Talk to IntelliMate"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label

        subtitleLabel.text = "Speak naturally and get real-time AI responses."
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 6
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        orbView.isUserInteractionEnabled = false
        orbView.setState(.idle)
        orbView.translatesAutoresizingMaskIntoConstraints = false

        statusContainer.backgroundColor = .secondarySystemBackground
        statusContainer.layer.cornerRadius = 16
        statusContainer.translatesAutoresizingMaskIntoConstraints = false

        statusDot.layer.cornerRadius = 4
        statusDot.backgroundColor = .systemGray3
        statusDot.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        statusLabel.textColor = .label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        statusContainer.addSubview(statusDot)
        statusContainer.addSubview(statusLabel)

        headerContainer.addSubview(headerStack)
        headerContainer.addSubview(orbView)
        headerContainer.addSubview(statusContainer)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 20),
            headerStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -20),

            orbView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16),
            orbView.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            orbView.widthAnchor.constraint(equalToConstant: 110),
            orbView.heightAnchor.constraint(equalToConstant: 110),

            statusDot.widthAnchor.constraint(equalToConstant: 8),
            statusDot.heightAnchor.constraint(equalToConstant: 8),
            statusDot.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 14),
            statusDot.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusContainer.trailingAnchor, constant: -14),
            statusLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),

            statusContainer.topAnchor.constraint(equalTo: orbView.bottomAnchor, constant: 14),
            statusContainer.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            statusContainer.heightAnchor.constraint(equalToConstant: 32),
            statusContainer.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -12)
        ])
    }

    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // Placeholder shown behind the (empty) rows area until the first message arrives.
        emptyStateLabel.text = "Your conversation will appear here.\nTap \"Start Talking\" to begin."
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = .systemFont(ofSize: 14)
        emptyStateLabel.textColor = .tertiaryLabel

        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.frame = CGRect(x: 0, y: 0, width: 320, height: 300) // placeholder, resized in sizeHeaderToFit()
        tableView.tableHeaderView = headerContainer
    }

    private func setupBottomBar() {
        bottomBar.backgroundColor = .systemBackground
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        let topBorder = UIView()
        topBorder.backgroundColor = .separator
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(topBorder)

        configureLabeledButton(startButton, title: "Start Talking", systemImage: "waveform", color: .systemBlue)
        configureLabeledButton(stopButton, title: "Stop", systemImage: "stop.fill", color: .systemGray5, titleColor: .label)
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [startButton, stopButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            topBorder.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            buttonStack.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            buttonStack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 52),
            buttonStack.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -12)
        ])
    }

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configureLabeledButton(_ button: UIButton, title: String, systemImage: String, color: UIColor, titleColor: UIColor = .white) {
        button.setTitle("  \(title)", for: .normal)
        button.setImage(UIImage(systemName: systemImage), for: .normal)
        button.tintColor = titleColor
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = color
        button.setTitleColor(titleColor, for: .normal)
        button.layer.cornerRadius = 16
        button.semanticContentAttribute = .forceLeftToRight
    }

    private func sizeHeaderToFit() {
        guard let header = tableView.tableHeaderView, tableView.bounds.width > 0 else { return }

        let targetWidth = tableView.bounds.width
        let size = header.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        if header.frame.height != size.height || header.frame.width != targetWidth {
            header.frame = CGRect(x: 0, y: 0, width: targetWidth, height: size.height)
            tableView.tableHeaderView = header
        }
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.applyState(state)
            }
        }

        viewModel.onTranscript = { [weak self] text, role in
            DispatchQueue.main.async {
                self?.appendMessage(text: text, roleString: role)
            }
        }

        viewModel.onError = { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusLabel.text = "Failed"
                self.appendMessage(text: error, roleString: "system")
                self.orbView.setState(.idle)
            }
        }
    }

    private func applyInitialState() {
        statusLabel.text = "Disconnected"
        statusDot.backgroundColor = .systemGray3
        orbView.setState(.idle)
        stopButton.isEnabled = false
        speakerBarButtonItem.isEnabled = false
        micBarButtonItem.isEnabled = false
    }

    private func applyState(_ state: VoiceConnectionState) {
        switch state {
        case .disconnected:
            statusLabel.text = "Disconnected"
            statusDot.backgroundColor = .systemGray3
            statusContainer.backgroundColor = .secondarySystemBackground
            orbView.setState(.idle)
            startButton.isEnabled = true
            stopButton.isEnabled = false
            speakerBarButtonItem.isEnabled = false
            micBarButtonItem.isEnabled = false

        case .connecting:
            statusLabel.text = "Connecting..."
            statusDot.backgroundColor = .systemOrange
            statusContainer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
            orbView.setState(.thinking)
            startButton.isEnabled = false
            stopButton.isEnabled = true
            speakerBarButtonItem.isEnabled = false
            micBarButtonItem.isEnabled = false

        case .connected:
            statusLabel.text = currentStatusText()
            statusDot.backgroundColor = .systemGreen
            statusContainer.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
            orbView.setState(.listening)
            startButton.isEnabled = false
            stopButton.isEnabled = true
            speakerBarButtonItem.isEnabled = true
            micBarButtonItem.isEnabled = true

        case .failed:
            statusLabel.text = "Connection Failed"
            statusDot.backgroundColor = .systemRed
            statusContainer.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
            orbView.setState(.idle)
            startButton.isEnabled = true
            stopButton.isEnabled = false
            speakerBarButtonItem.isEnabled = false
            micBarButtonItem.isEnabled = false

        @unknown default:
            statusLabel.text = "Unknown"
            statusDot.backgroundColor = .systemGray3
            statusContainer.backgroundColor = .secondarySystemBackground
            orbView.setState(.idle)
            startButton.isEnabled = true
            stopButton.isEnabled = false
            speakerBarButtonItem.isEnabled = false
            micBarButtonItem.isEnabled = false
        }

        updateSpeakerUI()
        updateMicUI()
        sizeHeaderToFit() // status text length can change, which can change header height
    }

    private func currentStatusText() -> String {
        if isSpeakerMuted && isMicMuted {
            return "Listening • Speaker Muted • Mic Muted"
        } else if isSpeakerMuted {
            return "Listening • Speaker Muted"
        } else if isMicMuted {
            return "Listening • Mic Muted"
        } else {
            return "Listening"
        }
    }

    private func updateSpeakerUI() {
        let imageName = isSpeakerMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        speakerBarButtonItem.image = UIImage(systemName: imageName)
        speakerBarButtonItem.tintColor = isSpeakerMuted ? .systemRed : .systemGreen
    }

    private func updateMicUI() {
        let imageName = isMicMuted ? "mic.slash.fill" : "mic.fill"
        micBarButtonItem.image = UIImage(systemName: imageName)
        micBarButtonItem.tintColor = isMicMuted ? .systemRed : .systemGreen
    }

    // MARK: - Chat transcript management

    private func appendMessage(text: String, roleString: String?) {
        let message = VoiceChatMessage(text: text, roleString: roleString)
        messages.append(message)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .fade)
        updateEmptyState()
        scrollToBottom()
    }

    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    private func updateEmptyState() {
        tableView.backgroundView = messages.isEmpty ? emptyStateLabel : nil
    }

    private func clearChat() {
        messages.removeAll()
        tableView.reloadData()
        updateEmptyState()
    }

    // MARK: - Actions

    @objc private func startTapped() {
        clearChat()
        viewModel.startVoiceCall()
    }

    @objc private func stopTapped() {
        viewModel.stopVoiceCall()
        applyInitialState()
    }

    @objc private func didTapSpeaker() {
        isSpeakerMuted.toggle()
        viewModel.setSpeakerMuted(isSpeakerMuted)
        updateSpeakerUI()

        if case .connected = viewModel.state {
            statusLabel.text = currentStatusText()
        }
    }

    @objc private func didTapMic() {
        isMicMuted.toggle()
        viewModel.setMicMuted(isMicMuted)
        updateMicUI()

        if case .connected = viewModel.state {
            statusLabel.text = currentStatusText()
        }
    }

    @objc private func clearChatTapped() {
        guard !messages.isEmpty else { return }

        let alert = UIAlertController(
            title: "Clear Chat?",
            message: "This will remove the entire conversation transcript. This can't be undone.",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Clear Chat", style: .destructive) { [weak self] _ in
            self?.clearChat()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource / UITableViewDelegate

extension AdvancedVoiceViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatMessageCell.reuseIdentifier,
            for: indexPath
        ) as? ChatMessageCell else {
            return UITableViewCell()
        }
        cell.configure(with: messages[indexPath.row])
        return cell
    }
} 
