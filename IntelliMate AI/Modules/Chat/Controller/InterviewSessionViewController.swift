//
//  InterviewSessionViewController.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 09/07/26.
//


import UIKit

private enum FeedItem {
    case question(String)
    case answer(question: String, answer: String)
    case debug(String)
}

final class InterviewSessionViewController: UIViewController {

    private let candidateProfileId: String
    private let socketService = InterviewWebSocketService()
    private let audioRecorder = InterviewAudioRecorder()

    private let headerCard = UIView()
    private let statusPill = StatusPill()
    private let sessionLabel = UILabel()
    private let waveformStack = UIStackView()
    private var waveformBars: [UIView] = []

    private let feedTableView = UITableView()
    private let emptyStateLabel = UILabel()
    private let endButton = UIButton(type: .system)

    private var feedItems: [FeedItem] = []
    private var lastInterviewerTranscript: String?
    private var hasShownTerminalAlert = false
    private var isEndingInterview = false
    
    init(candidateProfileId: String) {
        self.candidateProfileId = candidateProfileId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        title = "Live Interview"
        navigationItem.hidesBackButton = true
        navigationItem.largeTitleDisplayMode = .never

        socketService.delegate = self
        audioRecorder.delegate = self

        buildUI()
        connect()
    }

    deinit {
        audioRecorder.stopStreaming()
        socketService.disconnect()
    }

    private func buildUI() {
        buildHeaderCard()
        buildFeedTable()
        buildEndButton()

        [headerCard, feedTableView, emptyStateLabel, endButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            feedTableView.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: 12),
            feedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            feedTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            feedTableView.bottomAnchor.constraint(equalTo: endButton.topAnchor, constant: -12),

            emptyStateLabel.centerXAnchor.constraint(equalTo: feedTableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: feedTableView.centerYAnchor, constant: -40),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),

            endButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            endButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            endButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func buildHeaderCard() {
        headerCard.backgroundColor = Theme.cardBackground
        headerCard.layer.cornerRadius = Theme.cornerRadiusLarge
        headerCard.addCardShadow()

        statusPill.configure(text: "Connecting…", style: .warning)

        sessionLabel.font = .systemFont(ofSize: 12, weight: .medium)
        sessionLabel.textColor = Theme.textSecondary
        sessionLabel.text = "Session: —"

        waveformStack.axis = .horizontal
        waveformStack.spacing = 4
        waveformStack.alignment = .center
        waveformStack.distribution = .fillEqually

        for _ in 0..<5 {
            let bar = UIView()
            bar.backgroundColor = Theme.accent
            bar.layer.cornerRadius = 2
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.heightAnchor.constraint(equalToConstant: 6).isActive = true
            bar.widthAnchor.constraint(equalToConstant: 4).isActive = true
            waveformStack.addArrangedSubview(bar)
            waveformBars.append(bar)
        }

        let topRow = UIStackView(arrangedSubviews: [statusPill, UIView(), waveformStack])
        topRow.axis = .horizontal
        topRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [topRow, sessionLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16)
        ])
    }

    private func buildFeedTable() {
        feedTableView.register(FeedQuestionCell.self, forCellReuseIdentifier: FeedQuestionCell.reuseId)
        feedTableView.register(FeedAnswerCell.self, forCellReuseIdentifier: FeedAnswerCell.reuseId)
        feedTableView.register(FeedDebugCell.self, forCellReuseIdentifier: FeedDebugCell.reuseId)
        feedTableView.dataSource = self
        feedTableView.delegate = self
        feedTableView.separatorStyle = .none
        feedTableView.backgroundColor = .clear
        feedTableView.rowHeight = UITableView.automaticDimension
        feedTableView.estimatedRowHeight = 100

        emptyStateLabel.text = "Waiting for the interviewer to speak.\nQuestions and answers will appear here."
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = .systemFont(ofSize: 14)
        emptyStateLabel.textColor = Theme.textSecondary
    }

    private func buildEndButton() {
        var config = UIButton.Configuration.filled()
        config.title = "End Interview"
        config.image = UIImage(systemName: "xmark.circle.fill")
        config.imagePadding = 8
        config.baseBackgroundColor = Theme.danger
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        endButton.configuration = config
        endButton.addTarget(self, action: #selector(endTapped), for: .touchUpInside)
    }

    private func startWaveformAnimation() {
        for (index, bar) in waveformBars.enumerated() {
            let anim = CABasicAnimation(keyPath: "bounds.size.height")
            anim.fromValue = 4
            anim.toValue = CGFloat.random(in: 14...22)
            anim.duration = 0.4
            anim.autoreverses = true
            anim.repeatCount = .infinity
            anim.beginTime = CACurrentMediaTime() + Double(index) * 0.12
            bar.layer.add(anim, forKey: "wave")
        }
    }

    private func stopWaveformAnimation() {
        waveformBars.forEach { $0.layer.removeAllAnimations() }
    }

    private func connect() {
        socketService.connect(candidateProfileId: candidateProfileId)
    }

    @objc private func endTapped() {
        let alert = UIAlertController(
            title: "End Interview?",
            message: "This will stop listening and disconnect.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "End", style: .destructive) { [weak self] _ in
            guard let self else { return }

            DispatchQueue.main.async {
                self.isEndingInterview = true
                self.audioRecorder.stopStreaming()
                self.socketService.disconnect()
                self.navigationController?.popToRootViewController(animated: true)
            }
        })

        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }

    private func appendQuestion(_ text: String) {
        DispatchQueue.main.async {
            guard !text.isEmpty else { return }
            self.emptyStateLabel.isHidden = true
            self.feedItems.append(.question(text))
            let indexPath = IndexPath(row: self.feedItems.count - 1, section: 0)
            self.feedTableView.insertRows(at: [indexPath], with: .fade)
            self.scrollToBottom()
        }
    }

    private func appendAnswer(question: String, answer: String) {
        DispatchQueue.main.async {
            self.emptyStateLabel.isHidden = true

            if let last = self.feedItems.last,
               case .question(let lastQuestion) = last,
               lastQuestion == question {
                self.feedItems[self.feedItems.count - 1] = .answer(question: question, answer: answer)
                let indexPath = IndexPath(row: self.feedItems.count - 1, section: 0)
                self.feedTableView.reloadRows(at: [indexPath], with: .fade)
            } else {
                self.feedItems.append(.answer(question: question, answer: answer))
                let indexPath = IndexPath(row: self.feedItems.count - 1, section: 0)
                self.feedTableView.insertRows(at: [indexPath], with: .fade)
            }

            self.scrollToBottom()
        }
    }

    private func appendDebug(_ text: String) {
        DispatchQueue.main.async {
            self.emptyStateLabel.isHidden = true
            self.feedItems.append(.debug(text))
            let indexPath = IndexPath(row: self.feedItems.count - 1, section: 0)
            self.feedTableView.insertRows(at: [indexPath], with: .none)
            self.scrollToBottom()
        }
    }

    private func scrollToBottom() {
        guard !feedItems.isEmpty else { return }
        let indexPath = IndexPath(row: feedItems.count - 1, section: 0)
        feedTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    private func presentTerminalAlertOnce(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard !self.hasShownTerminalAlert else { return }
            guard self.view.window != nil else { return }

            self.hasShownTerminalAlert = true

            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

extension InterviewSessionViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        feedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch feedItems[indexPath.row] {
        case .question(let text):
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedQuestionCell.reuseId, for: indexPath) as! FeedQuestionCell
            cell.configure(text: text)
            return cell

        case .answer(let question, let answer):
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedAnswerCell.reuseId, for: indexPath) as! FeedAnswerCell
            cell.configure(question: question, answer: answer)
            return cell

        case .debug(let text):
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedDebugCell.reuseId, for: indexPath) as! FeedDebugCell
            cell.configure(text: text)
            return cell
        }
    }
}

extension InterviewSessionViewController: InterviewAudioRecorderDelegate {
    func didPrepareEnrollmentFile(url: URL) {}
    func didFinishEnrollmentRecording(url: URL) {}

    func didFailAudioRecorder(error: Error) {
        DispatchQueue.main.async {
            self.statusPill.configure(text: "Audio error", style: .danger)
            self.stopWaveformAnimation()
            self.presentTerminalAlertOnce(title: "Microphone issue", message: error.localizedDescription)
        }
    }

    func didProduceStreamingAudioChunk(_ data: Data) {
        _ = socketService.sendAudioChunk(data)
    }
}

extension InterviewSessionViewController: InterviewWebSocketServiceDelegate {
    func didConnectSession(sessionId: String) {
        DispatchQueue.main.async {
            self.sessionLabel.text = "Session: \(sessionId.prefix(8))…"
            self.statusPill.configure(text: "Listening for interviewer", style: .active)
            self.startWaveformAnimation()
        }

        audioRecorder.requestPermission { [weak self] granted in
            guard let self else { return }

            DispatchQueue.main.async {
                if granted {
                    self.audioRecorder.startStreaming()
                } else {
                    self.statusPill.configure(text: "Mic permission denied", style: .danger)
                    self.stopWaveformAnimation()
                }
            }
        }
    }

    func didRegisterInterviewer(profileId: String) {
        DispatchQueue.main.async {
            self.statusPill.configure(text: "Interviewer detected", style: .success)
        }
    }

    func didReceiveTranscript(_ transcript: WSTranscriptMessage) {
        DispatchQueue.main.async {
            self.emptyStateLabel.isHidden = true

            switch transcript.speaker.lowercased() {
            case "interviewer":
                let normalized = transcript.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !normalized.isEmpty else { return }

                if self.lastInterviewerTranscript != normalized {
                    self.lastInterviewerTranscript = normalized
                    self.appendQuestion(normalized)
                }

            case "unknown":
                let score = transcript.similarity ?? 0
                self.appendDebug("unclear speaker (\(String(format: "%.2f", score))): \(transcript.text)")

            default:
                break
            }
        }
    }

    func didReceiveAnswer(_ answer: WSAnswerMessage) {
        DispatchQueue.main.async {
            self.appendAnswer(question: answer.question, answer: answer.answer)
        }
    }

    func didReceiveDroppedUtterance(reason: String, score: Double) {
        DispatchQueue.main.async {
            self.appendDebug("dropped (\(String(format: "%.2f", score))) — \(reason)")
        }
    }

    func didReceiveSocketError(_ message: String) {
        DispatchQueue.main.async {
            guard !self.isEndingInterview else { return }
            self.statusPill.configure(text: "Error", style: .danger)
            self.stopWaveformAnimation()
            self.audioRecorder.stopStreaming()
            self.presentTerminalAlertOnce(title: "Connection issue", message: message)
        }
    }

    func didDisconnect() {
        DispatchQueue.main.async {
            guard !self.isEndingInterview else { return }
            self.statusPill.configure(text: "Disconnected", style: .idle)
            self.stopWaveformAnimation()
            self.audioRecorder.stopStreaming()
        }
    }
}
