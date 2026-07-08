//
//  InterviewAssistantViewModel.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import Foundation

enum InterviewAssistantState {
    case idle
    case requestingPermission
    case ready
    case recordingEnrollment
    case enrolling
    case enrolled
    case failed(String)
}

final class InterviewAssistantViewModel: NSObject {
    private let apiService: InterviewAPIService
    private let recorder: InterviewAudioRecorder

    private(set) var profileID: String?
    private var currentRecordingURL: URL?

    var onStateChange: ((InterviewAssistantState) -> Void)?
    var onStatusTextChange: ((String) -> Void)?
    var onProfileChange: ((String?) -> Void)?

    init(
        apiService: InterviewAPIService = .shared,
        recorder: InterviewAudioRecorder = InterviewAudioRecorder()
    ) {
        self.apiService = apiService
        self.recorder = recorder
        super.init()
        self.recorder.delegate = self
    }

    func prepare() {
        onStateChange?(.idle)
        onStatusTextChange?("Ready")
        onProfileChange?(profileID)
    }

    func requestMicrophonePermission() {
        onStateChange?(.requestingPermission)

        recorder.requestPermission { [weak self] granted in
            guard let self else { return }

            if granted {
                self.onStateChange?(.ready)
                self.onStatusTextChange?("Microphone permission granted")
            } else {
                self.onStateChange?(.failed("Microphone permission denied"))
                self.onStatusTextChange?("Microphone permission denied")
            }
        }
    }

    func startEnrollmentRecording() {
        currentRecordingURL = nil
        recorder.startEnrollmentRecording(fileName: "candidate_enrollment.m4a")
        onStateChange?(.recordingEnrollment)
        onStatusTextChange?("Recording candidate voice sample...")
    }

    func stopEnrollmentRecordingAndUpload() {
        recorder.stopEnrollmentRecording()

        guard let fileURL = currentRecordingURL else {
            onStateChange?(.failed("Missing enrollment recording"))
            onStatusTextChange?("Missing enrollment recording")
            return
        }

        onStateChange?(.enrolling)
        onStatusTextChange?("Uploading enrollment voice...")

        apiService.enrollCandidate(audioFileURL: fileURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success(let response):
                    self.profileID = response.profileId
                    self.onProfileChange?(response.profileId)
                    self.onStateChange?(.enrolled)
                    self.onStatusTextChange?("Voice enrolled successfully")

                case .failure(let error):
                    self.onStateChange?(.failed(error.localizedDescription))
                    self.onStatusTextChange?("Enrollment failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension InterviewAssistantViewModel: InterviewAudioRecorderDelegate {
    func didFinishEnrollmentRecording(url: URL) {
        // Not used in this ViewModel.
    }
    
    func didPrepareEnrollmentFile(url: URL) {
        currentRecordingURL = url
    }

    func didFailAudioRecorder(error: Error) {
        onStateChange?(.failed(error.localizedDescription))
        onStatusTextChange?("Audio error: \(error.localizedDescription)")
    }

    func didProduceStreamingAudioChunk(_ data: Data) {
        // Not used in this ViewModel.
    }
}
