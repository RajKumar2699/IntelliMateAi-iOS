//
//  InterviewViewController.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import UIKit

final class InterviewViewController: UIViewController {

    private let apiService = InterviewAPIService.shared
    private let socketService = InterviewWebSocketService()
    private let audioRecorder = InterviewAudioRecorder()

    private let statusLabel = UILabel()
    private let profileIdLabel = UILabel()
    private let sessionIdLabel = UILabel()
    private let answerLabel = UILabel()

    private let startEnrollButton = UIButton(type: .system)
    private let stopEnrollButton = UIButton(type: .system)
    private let connectButton = UIButton(type: .system)
    private let startStreamingButton = UIButton(type: .system)
    private let stopStreamingButton = UIButton(type: .system)

    private let transcriptView = UITextView()

    private var enrolledProfileId: String?
    private var sampleAudioURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        socketService.delegate = self
        audioRecorder.delegate = self
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Interview Assistant"

        statusLabel.text = "Status: Idle"
        statusLabel.numberOfLines = 0

        profileIdLabel.text = "Profile ID: -"
        profileIdLabel.numberOfLines = 0

        sessionIdLabel.text = "Session ID: -"
        sessionIdLabel.numberOfLines = 0

        answerLabel.text = "Answer: -"
        answerLabel.numberOfLines = 0

        startEnrollButton.setTitle("Start Enroll Recording", for: .normal)
        stopEnrollButton.setTitle("Stop & Enroll", for: .normal)
        connectButton.setTitle("Connect WebSocket", for: .normal)
        startStreamingButton.setTitle("Start Streaming", for: .normal)
        stopStreamingButton.setTitle("Stop Streaming", for: .normal)

        startEnrollButton.addTarget(self, action: #selector(startEnrollTapped), for: .touchUpInside)
        stopEnrollButton.addTarget(self, action: #selector(stopEnrollTapped), for: .touchUpInside)
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
        startStreamingButton.addTarget(self, action: #selector(startStreamingTapped), for: .touchUpInside)
        stopStreamingButton.addTarget(self, action: #selector(stopStreamingTapped), for: .touchUpInside)

        transcriptView.isEditable = false
        transcriptView.font = .systemFont(ofSize: 16)

        let stack = UIStackView(arrangedSubviews: [
            statusLabel,
            profileIdLabel,
            sessionIdLabel,
            answerLabel,
            startEnrollButton,
            stopEnrollButton,
            connectButton,
            startStreamingButton,
            stopStreamingButton,
            transcriptView
        ])

        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            transcriptView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260)
        ])
    }

    @objc private func startEnrollTapped() {
        audioRecorder.requestPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                if granted {
                    self.updateStatus("Recording enrollment sample...")
                    self.audioRecorder.startEnrollmentRecording()
                } else {
                    self.updateStatus("Microphone permission denied")
                }
            }
        }
    }

    @objc private func stopEnrollTapped() {
        updateStatus("Finalizing enrollment file...")
        audioRecorder.stopEnrollmentRecording()
    }

    @objc private func connectTapped() {
        guard let profileId = enrolledProfileId else {
            updateStatus("Enroll candidate first")
            return
        }

        updateStatus("Connecting WebSocket...")
        socketService.connect(candidateProfileId: profileId)
    }

    @objc private func startStreamingTapped() {
        audioRecorder.requestPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                if granted {
                    self.updateStatus("Streaming live audio...")
                    self.audioRecorder.startStreaming()
                } else {
                    self.updateStatus("Microphone permission denied")
                }
            }
        }
    }

    @objc private func stopStreamingTapped() {
        audioRecorder.stopStreaming()
        socketService.disconnect()
        updateStatus("Streaming stopped")
    }

    private func updateStatus(_ text: String) {
        statusLabel.text = "Status: \(text)"
    }
}

extension InterviewViewController: InterviewWebSocketServiceDelegate {
    func didConnectSession(sessionId: String) {
        sessionIdLabel.text = "Session ID: \(sessionId)"
        updateStatus("Socket connected")
    }

    func didRegisterInterviewer(profileId: String) {
        updateStatus("Interviewer registered: \(profileId)")
    }

    func didReceiveTranscript(_ transcript: WSTranscriptMessage) {
        let current = transcriptView.text ?? ""
        transcriptView.text = current + "\n[\(transcript.speaker)] \(transcript.text)"
    }

    func didReceiveAnswer(_ answer: WSAnswerMessage) {
        answerLabel.text = "Answer: \(answer.answer)"
    }

    func didReceiveSocketError(_ message: String) {
        updateStatus("Socket error: \(message)")
    }

    func didDisconnect() {
        updateStatus("Socket disconnected")
    }
}

extension InterviewViewController: InterviewAudioRecorderDelegate {
    func didPrepareEnrollmentFile(url: URL) {
        sampleAudioURL = url
    }

    func didFinishEnrollmentRecording(url: URL) {
        sampleAudioURL = url
        updateStatus("Uploading enrollment voice...")

        apiService.enrollCandidate(audioFileURL: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.enrolledProfileId = response.profileId
                    self?.profileIdLabel.text = "Profile ID: \(response.profileId)"
                    self?.updateStatus(response.message)

                case .failure(let error):
                    self?.updateStatus("Enroll failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func didFailAudioRecorder(error: Error) {
        updateStatus("Audio error: \(error.localizedDescription)")
    }

    func didProduceStreamingAudioChunk(_ data: Data) {
        socketService.sendAudioChunk(data)
    }
}
