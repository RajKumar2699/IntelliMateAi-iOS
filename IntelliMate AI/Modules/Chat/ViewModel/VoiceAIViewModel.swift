//
//  VoiceAIViewModel.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 06/07/26.
//


import Foundation
import AVFoundation

final class VoiceAIViewModel: NSObject {
    enum State {
        case idle
        case listening
        case thinking
        case speaking
    }

    private let repository: VoiceRepository
    private let speechService: SpeechRecognizerService
    private let synthesizer = AVSpeechSynthesizer()

    private var pendingSpeechBuffer = ""
    private var fullReply = ""

    var onTranscriptChanged: ((String) -> Void)?
    var onStateChanged: ((State) -> Void)?
    var onError: ((String) -> Void)?

    init(repository: VoiceRepository, speechService: SpeechRecognizerService) {
        self.repository = repository
        self.speechService = speechService
        super.init()
        synthesizer.delegate = self
        bindSpeech()
    }

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        speechService.requestPermissions(completion: completion)
    }

    func startListening() {
        stopSpeaking()
        onStateChanged?(.listening)
        speechService.startListening()
    }

    func stopListeningAndSend() {
        speechService.stopListening()
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        pendingSpeechBuffer = ""
    }

    private func bindSpeech() {
        speechService.onText = { [weak self] text in
            DispatchQueue.main.async {
                self?.onTranscriptChanged?(text)
            }
        }

        speechService.onFinalText = { [weak self] text in
            self?.streamReply(for: text)
        }

        speechService.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.onStateChanged?(.idle)
                self?.onError?(message)
            }
        }
    }

    private func streamReply(for text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                self.onStateChanged?(.idle)
            }
            return
        }

        Task {
            await MainActor.run {
                self.onStateChanged?(.thinking)
                self.fullReply = ""
                self.pendingSpeechBuffer = ""
                self.onTranscriptChanged?("")
            }

            do {
                for try await chunk in repository.streamReply(message: text) {
                    await MainActor.run {
                        self.fullReply += chunk
                        self.pendingSpeechBuffer += chunk
                        self.onStateChanged?(.speaking)
                        self.onTranscriptChanged?(self.fullReply)
                        self.speakCompletedSentencesIfNeeded()
                    }
                }

                await MainActor.run {
                    self.speakRemainingTextIfNeeded()
                    if !self.synthesizer.isSpeaking {
                        self.onStateChanged?(.idle)
                    }
                }
            } catch {
                await MainActor.run {
                    self.onStateChanged?(.idle)
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }

    private func speakCompletedSentencesIfNeeded() {
        let delimiters = CharacterSet(charactersIn: ".!?")
        guard let range = pendingSpeechBuffer.rangeOfCharacter(from: delimiters) else { return }

        let sentence = String(pendingSpeechBuffer[..<range.upperBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let remainder = String(pendingSpeechBuffer[range.upperBound...])

        pendingSpeechBuffer = remainder

        if !sentence.isEmpty {
            speak(sentence)
        }

        speakCompletedSentencesIfNeeded()
    }

    private func speakRemainingTextIfNeeded() {
        let finalText = pendingSpeechBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingSpeechBuffer = ""

        if !finalText.isEmpty {
            speak(finalText)
        }
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.50
        utterance.pitchMultiplier = 1.0
        utterance.prefersAssistiveTechnologySettings = true
        synthesizer.speak(utterance)
    }
}

extension VoiceAIViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if !synthesizer.isSpeaking {
            DispatchQueue.main.async { [weak self] in
                self?.onStateChanged?(.idle)
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.onStateChanged?(.idle)
        }
    }
}
