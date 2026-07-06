//
//  SpeechRecognizerService.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 06/07/26.
//


import Foundation
import Speech
import AVFoundation

final class SpeechRecognizerService {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    var onText: ((String) -> Void)?
    var onFinalText: ((String) -> Void)?
    var onError: ((String) -> Void)?

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            AVAudioSession.sharedInstance().requestRecordPermission { micGranted in
                DispatchQueue.main.async {
                    completion(speechStatus == .authorized && micGranted)
                }
            }
        }
    }

    func startListening() {
        #if targetEnvironment(simulator)
        onError?("Voice mode should be tested on a real iPhone. Simulator microphone input can be unreliable.")
        return
        #endif

        stopListening()

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest?.shouldReportPartialResults = true

            guard let recognitionRequest = recognitionRequest,
                  let recognizer = recognizer,
                  recognizer.isAvailable else {
                onError?("Speech recognizer is not available.")
                return
            }

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            guard recordingFormat.sampleRate > 0,
                  recordingFormat.channelCount > 0 else {
                onError?("Invalid microphone input format.")
                return
            }

            inputNode.removeTap(onBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                recognitionRequest.append(buffer)
                let power = self?.normalizedPower(from: buffer) ?? 0.08
                NotificationCenter.default.post(name: .voiceOrbPowerDidChange, object: power)
            }

            audioEngine.prepare()
            try audioEngine.start()

            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    self?.onText?(text)

                    if result.isFinal {
                        self?.onFinalText?(text)
                    }
                }

                if let error = error {
                    self?.onError?(error.localizedDescription)
                    self?.stopListening()
                }
            }
        } catch {
            onError?(error.localizedDescription)
        }
    }

    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        audioEngine.inputNode.removeTap(onBus: 0)

        NotificationCenter.default.post(name: .voiceOrbPowerDidChange, object: CGFloat(0.0))
    }

    private func normalizedPower(from buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let channelData = buffer.floatChannelData?[0], buffer.frameLength > 0 else {
            return 0.08
        }

        let values = stride(from: 0, to: Int(buffer.frameLength), by: Int(buffer.stride)).map { channelData[$0] }
        let rms = sqrt(values.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        return min(max(CGFloat(rms) * 8.0, 0.08), 1.0)
    }
}

extension Notification.Name {
    static let voiceOrbPowerDidChange = Notification.Name("voiceOrbPowerDidChange")
}
