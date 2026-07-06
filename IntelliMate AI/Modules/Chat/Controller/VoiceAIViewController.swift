//
//  VoiceAIViewController.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 06/07/26.
//


import UIKit

final class VoiceAIViewController: UIViewController {
    private let viewModel: VoiceAIViewModel

    private let orbView = OrbView()
    private let stateLabel = UILabel()
    private let transcriptLabel = UILabel()
    private let micButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)

    private var isListening = false

    init(viewModel: VoiceAIViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindViewModel()
        requestPermissions()
    }

    private func configureUI() {
        title = "Voice AI"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = UIColor(red: 0.03, green: 0.05, blue: 0.10, alpha: 1.0)

        orbView.translatesAutoresizingMaskIntoConstraints = false
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        transcriptLabel.translatesAutoresizingMaskIntoConstraints = false
        micButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.translatesAutoresizingMaskIntoConstraints = false

        stateLabel.text = "Tap to start"
        stateLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        stateLabel.textAlignment = .center
        stateLabel.textColor = .white

        transcriptLabel.text = "Start speaking to your AI"
        transcriptLabel.font = .systemFont(ofSize: 17, weight: .regular)
        transcriptLabel.textAlignment = .center
        transcriptLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        transcriptLabel.numberOfLines = 0

        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor = .white
        micButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.95)
        micButton.layer.cornerRadius = 34
        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)

        stopButton.setTitle("Stop", for: .normal)
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        stopButton.layer.cornerRadius = 22
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)

        view.addSubview(orbView)
        view.addSubview(stateLabel)
        view.addSubview(transcriptLabel)
        view.addSubview(micButton)
        view.addSubview(stopButton)

        NSLayoutConstraint.activate([
            orbView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            orbView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -70),
            orbView.widthAnchor.constraint(equalToConstant: 220),
            orbView.heightAnchor.constraint(equalToConstant: 220),

            stateLabel.topAnchor.constraint(equalTo: orbView.bottomAnchor, constant: 32),
            stateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            transcriptLabel.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 14),
            transcriptLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            transcriptLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            micButton.widthAnchor.constraint(equalToConstant: 68),
            micButton.heightAnchor.constraint(equalToConstant: 68),

            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopButton.bottomAnchor.constraint(equalTo: micButton.topAnchor, constant: -16),
            stopButton.widthAnchor.constraint(equalToConstant: 92),
            stopButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func bindViewModel() {
        viewModel.onTranscriptChanged = { [weak self] text in
            DispatchQueue.main.async {
                self?.transcriptLabel.text = text
            }
        }

        viewModel.onStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .idle:
                    self?.stateLabel.text = "Tap to start"
                    self?.orbView.setState(.idle)
                    self?.isListening = false
                    self?.micButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.95)
                    self?.micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)

                case .listening:
                    self?.stateLabel.text = "Listening..."
                    self?.orbView.setState(.listening)
                    self?.isListening = true
                    self?.micButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.95)
                    self?.micButton.setImage(UIImage(systemName: "waveform"), for: .normal)

                case .thinking:
                    self?.stateLabel.text = "Thinking..."
                    self?.orbView.setState(.thinking)
                    self?.isListening = false

                case .speaking:
                    self?.stateLabel.text = "Responding..."
                    self?.orbView.setState(.speaking)
                    self?.isListening = false
                }
            }
        }

        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }

    private func requestPermissions() {
        viewModel.requestPermissions { [weak self] granted in
            if !granted {
                let alert = UIAlertController(
                    title: "Permission Required",
                    message: "Enable microphone and speech recognition permissions in Settings.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }

    @objc
    private func micTapped() {
        if isListening {
            viewModel.stopListeningAndSend()
        } else {
            transcriptLabel.text = "Listening..."
            viewModel.stopSpeaking()
            viewModel.startListening()
        }
    }

    @objc
    private func stopTapped() {
        viewModel.stopListeningAndSend()
        viewModel.stopSpeaking()
    }
}
