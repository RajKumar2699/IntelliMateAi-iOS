//
//  EnrollmentViewController.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 09/07/26.
//


import UIKit

final class EnrollmentViewController: UIViewController {

    private let apiService = InterviewAPIService.shared
    private let audioRecorder = InterviewAudioRecorder()

    private let requiredSamples = 3
    private var recordedSampleURLs: [URL] = []
    private var currentPreparedURL: URL?
    private var isRecording = false
    private var isUploading = false
    private var elapsedSeconds = 0
    private var recordingTimer: Timer?
    private var enrolledProfileId: String?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let heroCircle = UIView()
    private let micIconView = UIImageView()
    private let pulseLayer1 = CAShapeLayer()
    private let pulseLayer2 = CAShapeLayer()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusPill = StatusPill()

    private let recordCard = UIView()
    private let timerLabel = UILabel()
    private let sampleCountLabel = UILabel()
    private let primaryButton = UIButton(type: .system)
    private let secondaryButton = UIButton(type: .system)

    private let tipCard = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        audioRecorder.delegate = self
        view.backgroundColor = Theme.background
        title = "Voice Enrollment"
        navigationController?.navigationBar.prefersLargeTitles = false
        buildUI()
        refreshEnrollmentUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutPulseLayers()
    }

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        buildHero()
        buildRecordCard()
        buildTipCard()

        contentStack.addArrangedSubview(heroWrapper)
        contentStack.addArrangedSubview(headerWrapper)
        contentStack.addArrangedSubview(recordCard)
        contentStack.addArrangedSubview(tipCard)
        contentStack.setCustomSpacing(8, after: heroWrapper)
    }

    private lazy var heroWrapper: UIView = {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(heroCircle)

        NSLayoutConstraint.activate([
            heroCircle.topAnchor.constraint(equalTo: wrapper.topAnchor),
            heroCircle.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            heroCircle.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            heroCircle.widthAnchor.constraint(equalToConstant: 140),
            heroCircle.heightAnchor.constraint(equalToConstant: 140)
        ])

        return wrapper
    }()

    private func buildHero() {
        heroCircle.translatesAutoresizingMaskIntoConstraints = false
        heroCircle.backgroundColor = Theme.accentSoft
        heroCircle.layer.cornerRadius = 70

        pulseLayer1.fillColor = Theme.accent.withAlphaComponent(0.15).cgColor
        pulseLayer2.fillColor = Theme.accent.withAlphaComponent(0.08).cgColor
        heroCircle.layer.insertSublayer(pulseLayer2, at: 0)
        heroCircle.layer.insertSublayer(pulseLayer1, at: 0)

        micIconView.image = UIImage(systemName: "mic.fill")
        micIconView.tintColor = Theme.accent
        micIconView.contentMode = .scaleAspectFit
        micIconView.translatesAutoresizingMaskIntoConstraints = false
        heroCircle.addSubview(micIconView)

        NSLayoutConstraint.activate([
            micIconView.centerXAnchor.constraint(equalTo: heroCircle.centerXAnchor),
            micIconView.centerYAnchor.constraint(equalTo: heroCircle.centerYAnchor),
            micIconView.widthAnchor.constraint(equalToConstant: 44),
            micIconView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private lazy var headerWrapper: UIView = {
        titleLabel.text = "Let’s hear your voice"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = Theme.textPrimary

        subtitleLabel.text = "Record 3 short voice samples. Speak naturally so we can recognize your voice during the interview and focus on the interviewer."
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = Theme.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        statusPill.configure(text: "Idle", style: .idle)

        let pillWrapper = UIView()
        pillWrapper.translatesAutoresizingMaskIntoConstraints = false
        pillWrapper.addSubview(statusPill)

        NSLayoutConstraint.activate([
            statusPill.topAnchor.constraint(equalTo: pillWrapper.topAnchor),
            statusPill.bottomAnchor.constraint(equalTo: pillWrapper.bottomAnchor),
            statusPill.centerXAnchor.constraint(equalTo: pillWrapper.centerXAnchor)
        ])

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, pillWrapper])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        return container
    }()

    private func buildRecordCard() {
        recordCard.backgroundColor = Theme.cardBackground
        recordCard.layer.cornerRadius = Theme.cornerRadiusLarge
        recordCard.addCardShadow()
        recordCard.translatesAutoresizingMaskIntoConstraints = false

        sampleCountLabel.font = .systemFont(ofSize: 14, weight: .medium)
        sampleCountLabel.textColor = Theme.textSecondary
        sampleCountLabel.textAlignment = .center

        timerLabel.text = "00:00"
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 34, weight: .semibold)
        timerLabel.textColor = Theme.textPrimary
        timerLabel.textAlignment = .center

        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        secondaryButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [primaryButton, secondaryButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 10

        let stack = UIStackView(arrangedSubviews: [sampleCountLabel, timerLabel, buttonStack])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        recordCard.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: recordCard.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: recordCard.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: recordCard.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: recordCard.trailingAnchor, constant: -20)
        ])
    }

    private func buildTipCard() {
        tipCard.backgroundColor = Theme.accentSoft
        tipCard.layer.cornerRadius = Theme.cornerRadiusMedium
        tipCard.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "lightbulb.fill"))
        icon.tintColor = Theme.accent
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let text = UILabel()
        text.text = "Use a quiet room and speak naturally. A short self-introduction works well for each sample."
        text.font = .systemFont(ofSize: 13)
        text.textColor = Theme.textPrimary
        text.numberOfLines = 0
        text.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [icon, text])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .top
        stack.translatesAutoresizingMaskIntoConstraints = false
        tipCard.addSubview(stack)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),
            stack.topAnchor.constraint(equalTo: tipCard.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: tipCard.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: tipCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: tipCard.trailingAnchor, constant: -16)
        ])
    }

    private func filledButtonConfig(title: String, systemImage: String, color: UIColor) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: systemImage)
        config.imagePadding = 8
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        return config
    }

    private func tintedButtonConfig(title: String, color: UIColor) -> UIButton.Configuration {
        var config = UIButton.Configuration.gray()
        config.title = title
        config.baseForegroundColor = color
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        return config
    }

    private func layoutPulseLayers() {
        let center = CGPoint(x: heroCircle.bounds.midX, y: heroCircle.bounds.midY)
        pulseLayer1.path = UIBezierPath(
            arcCenter: center,
            radius: 70,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ).cgPath
        pulseLayer2.path = pulseLayer1.path
        pulseLayer1.frame = heroCircle.bounds
        pulseLayer2.frame = heroCircle.bounds
    }

    private func refreshEnrollmentUI() {
        sampleCountLabel.text = "Samples recorded: \(recordedSampleURLs.count) / \(requiredSamples)"

        if isUploading {
            statusPill.configure(text: "Uploading", style: .warning)
            primaryButton.isEnabled = false
            secondaryButton.isHidden = true
            primaryButton.configuration = tintedButtonConfig(title: "Processing", color: .systemGray)
            return
        }

        if let profileId = enrolledProfileId, !profileId.isEmpty {
            statusPill.configure(text: "Enrolled successfully", style: .success)
            primaryButton.isEnabled = true
            primaryButton.configuration = filledButtonConfig(
                title: "Continue to Interview",
                systemImage: "arrow.right",
                color: Theme.success
            )
            secondaryButton.isHidden = false
            secondaryButton.configuration = tintedButtonConfig(title: "Reset Samples", color: .systemGray)
            return
        }

        if isRecording {
            statusPill.configure(text: "Recording", style: .active)
            primaryButton.isEnabled = true
            primaryButton.configuration = filledButtonConfig(
                title: "Stop Sample",
                systemImage: "stop.fill",
                color: Theme.danger
            )
            secondaryButton.isHidden = false
            secondaryButton.configuration = tintedButtonConfig(title: "Cancel", color: .systemGray)
            return
        }

        if recordedSampleURLs.count < requiredSamples {
            let next = recordedSampleURLs.count + 1
            statusPill.configure(text: "Ready for sample \(next)", style: .idle)
            primaryButton.isEnabled = true
            primaryButton.configuration = filledButtonConfig(
                title: "Record Sample \(next)",
                systemImage: "mic.fill",
                color: Theme.accent
            )
            secondaryButton.isHidden = recordedSampleURLs.isEmpty
            secondaryButton.configuration = tintedButtonConfig(title: "Reset Samples", color: .systemGray)
            return
        }

        statusPill.configure(text: "Ready to upload", style: .warning)
        primaryButton.isEnabled = true
        primaryButton.configuration = filledButtonConfig(
            title: "Upload Samples",
            systemImage: "arrow.up.circle.fill",
            color: Theme.accent
        )
        secondaryButton.isHidden = false
        secondaryButton.configuration = tintedButtonConfig(title: "Reset Samples", color: .systemGray)
    }

    private func startPulseAnimation() {
        [pulseLayer1, pulseLayer2].enumerated().forEach { index, layer in
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 1.0
            scale.toValue = 1.6
            scale.duration = 1.6
            scale.beginTime = CACurrentMediaTime() + Double(index) * 0.5
            scale.repeatCount = .infinity
            scale.timingFunction = CAMediaTimingFunction(name: .easeOut)

            let opacity = CABasicAnimation(keyPath: "opacity")
            opacity.fromValue = 0.8
            opacity.toValue = 0.0
            opacity.duration = 1.6
            opacity.beginTime = CACurrentMediaTime() + Double(index) * 0.5
            opacity.repeatCount = .infinity

            let group = CAAnimationGroup()
            group.animations = [scale, opacity]
            group.duration = 1.6
            group.repeatCount = .infinity

            layer.add(group, forKey: "pulse")
        }
    }

    private func stopPulseAnimation() {
        pulseLayer1.removeAllAnimations()
        pulseLayer2.removeAllAnimations()
    }

    @objc private func primaryTapped() {
        if enrolledProfileId != nil {
            goToInterview()
            return
        }

        if isUploading { return }

        if isRecording {
            stopRecording()
            return
        }

        if recordedSampleURLs.count < requiredSamples {
            startRecording()
        } else {
            uploadSamples()
        }
    }

    @objc private func cancelTapped() {
        if isRecording {
            audioRecorder.stopEnrollmentRecording()
            isRecording = false
            stopTimer()
            stopPulseAnimation()
            currentPreparedURL = nil
            elapsedSeconds = 0
            timerLabel.text = "00:00"
            refreshEnrollmentUI()
            return
        }

        resetEnrollment()
    }

    private func startRecording() {
        audioRecorder.requestPermission { [weak self] granted in
            guard let self else { return }

            guard granted else {
                self.statusPill.configure(text: "Mic permission denied", style: .danger)
                self.showError("Please allow microphone access in Settings.")
                return
            }

            self.isRecording = true
            self.elapsedSeconds = 0
            self.timerLabel.text = "00:00"
            self.currentPreparedURL = nil

            let nextIndex = self.recordedSampleURLs.count + 1
            self.audioRecorder.startEnrollmentRecording(fileName: "candidate_enrollment_\(nextIndex).m4a")

            self.startTimer()
            self.startPulseAnimation()
            self.refreshEnrollmentUI()
        }
    }

    private func stopRecording() {
        guard isRecording else { return }

        isRecording = false
        stopTimer()
        stopPulseAnimation()

        statusPill.configure(text: "Finalizing sample", style: .warning)
        primaryButton.isEnabled = false
        secondaryButton.isHidden = true
        primaryButton.configuration = tintedButtonConfig(title: "Processing", color: .systemGray)

        audioRecorder.stopEnrollmentRecording()
    }

    private func uploadSamples() {
        guard recordedSampleURLs.count == requiredSamples else {
            showError("Please record all \(requiredSamples) samples before uploading.")
            return
        }

        isUploading = true
        refreshEnrollmentUI()

        apiService.enrollCandidate(audioFileURLs: recordedSampleURLs) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isUploading = false

                switch result {
                case .success(let response):
                    self.enrolledProfileId = response.profileId
                    self.refreshEnrollmentUI()

                case .failure(let error):
                    self.statusPill.configure(text: "Enrollment failed", style: .danger)
                    self.refreshEnrollmentUI()
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func resetEnrollment() {
        stopTimer()
        stopPulseAnimation()
        isRecording = false
        isUploading = false
        currentPreparedURL = nil
        elapsedSeconds = 0
        timerLabel.text = "00:00"
        enrolledProfileId = nil

        recordedSampleURLs.forEach { try? FileManager.default.removeItem(at: $0) }
        recordedSampleURLs.removeAll()

        refreshEnrollmentUI()
    }

    private func startTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1
            let m = self.elapsedSeconds / 60
            let s = self.elapsedSeconds % 60
            self.timerLabel.text = String(format: "%02d:%02d", m, s)
        }
    }

    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    private func goToInterview() {
        guard let profileId = enrolledProfileId else { return }
        let vc = InterviewSessionViewController(candidateProfileId: profileId)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension EnrollmentViewController: InterviewAudioRecorderDelegate {
    func didPrepareEnrollmentFile(url: URL) {
        currentPreparedURL = url
    }

    func didFinishEnrollmentRecording(url: URL) {
        let finalURL = currentPreparedURL ?? url

        if !recordedSampleURLs.contains(finalURL) {
            recordedSampleURLs.append(finalURL)
        }

        primaryButton.isEnabled = true
        elapsedSeconds = 0
        timerLabel.text = "00:00"

        if recordedSampleURLs.count < requiredSamples {
            statusPill.configure(text: "Sample saved", style: .success)
        } else {
            statusPill.configure(text: "All samples ready", style: .success)
        }

        refreshEnrollmentUI()
    }

    func didFailAudioRecorder(error: Error) {
        isRecording = false
        isUploading = false
        stopTimer()
        stopPulseAnimation()
        primaryButton.isEnabled = true
        statusPill.configure(text: "Audio error", style: .danger)
        refreshEnrollmentUI()
        showError(error.localizedDescription)
    }

    func didProduceStreamingAudioChunk(_ data: Data) {}
}
