//
//  AdvancedViewModel.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import Foundation

enum VoiceConnectionState {
    case disconnected
    case connecting
    case connected
    case failed
}

final class AdvancedVoiceViewModel {
    var onStateChange: ((VoiceConnectionState) -> Void)?
    var onTranscript: ((String, String?) -> Void)?
    var onError: ((String) -> Void)?

    private let realtimeManager: OpenAIRealtimeManager
    var preferredLanguageHint: String?

    private(set) var state: VoiceConnectionState = .disconnected {
        didSet { onStateChange?(state) }
    }

    private(set) var isSpeakerMuted = false
    private(set) var isMicMuted = false

    init(realtimeManager: OpenAIRealtimeManager, preferredLanguageHint: String? = nil) {
        self.realtimeManager = realtimeManager
        self.preferredLanguageHint = preferredLanguageHint
        self.realtimeManager.delegate = self
    }

    func startVoiceCall() {
        guard state != .connecting, state != .connected else { return }
        state = .connecting

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.realtimeManager.connect(languageHint: self.preferredLanguageHint)

                self.realtimeManager.setSpeakerMuted(self.isSpeakerMuted)
                self.realtimeManager.setMicMuted(self.isMicMuted)
            } catch {
                await MainActor.run {
                    self.state = .failed
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }

    func stopVoiceCall() {
        realtimeManager.disconnect()
        state = .disconnected
    }

    func sendText(_ text: String) {
        realtimeManager.sendText(text)
    }

    func setSpeakerMuted(_ muted: Bool) {
        isSpeakerMuted = muted
        realtimeManager.setSpeakerMuted(muted)
    }

    func setMicMuted(_ muted: Bool) {
        isMicMuted = muted
        realtimeManager.setMicMuted(muted)
    }
}

extension AdvancedVoiceViewModel: OpenAIRealtimeManagerDelegate {
    func realtimeManagerDidConnect(_ manager: OpenAIRealtimeManager) {
        DispatchQueue.main.async {
            self.state = .connected
        }
    }

    func realtimeManagerDidDisconnect(_ manager: OpenAIRealtimeManager) {
        DispatchQueue.main.async {
            self.state = .disconnected
        }
    }

    func realtimeManager(_ manager: OpenAIRealtimeManager, didReceiveTranscript text: String, role: String?) {
        DispatchQueue.main.async {
            self.onTranscript?(text, role)
        }
    }

    func realtimeManager(_ manager: OpenAIRealtimeManager, didFail error: Error) {
        DispatchQueue.main.async {
            self.state = .failed
            self.onError?(error.localizedDescription)
        }
    }
}
