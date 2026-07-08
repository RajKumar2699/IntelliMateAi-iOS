//
//  AudioSessionManager.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import Foundation
import AVFoundation
import WebRTC

final class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}

    enum AudioSessionError: LocalizedError {
        case microphonePermissionDenied

        var errorDescription: String? {
            switch self {
            case .microphonePermissionDenied:
                return "Microphone access is required for voice calls. Please enable it in Settings."
            }
        }
    }

    func configureForVoiceChat() throws {
        try requestMicrophonePermissionIfNeeded()

        let rtcSession = RTCAudioSession.sharedInstance()
        rtcSession.lockForConfiguration()
        defer { rtcSession.unlockForConfiguration() }

        let config = RTCAudioSessionConfiguration.webRTC()
        config.category = AVAudioSession.Category.playAndRecord.rawValue
        config.mode = AVAudioSession.Mode.voiceChat.rawValue
        config.categoryOptions = [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]

        try rtcSession.setConfiguration(config)
        try rtcSession.setActive(true)
    }

    func forceSpeakerRetry() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let rtcSession = RTCAudioSession.sharedInstance()
            rtcSession.lockForConfiguration()
            defer { rtcSession.unlockForConfiguration() }
            try? rtcSession.overrideOutputAudioPort(.speaker)
        }
    }

    private func requestMicrophonePermissionIfNeeded() throws {
        let semaphore = DispatchSemaphore(value: 0)
        var granted = false

        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                return
            case .denied:
                throw AudioSessionError.microphonePermissionDenied
            case .undetermined:
                AVAudioApplication.requestRecordPermission { result in
                    granted = result
                    semaphore.signal()
                }
                semaphore.wait()
            @unknown default:
                throw AudioSessionError.microphonePermissionDenied
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                return
            case .denied:
                throw AudioSessionError.microphonePermissionDenied
            case .undetermined:
                session.requestRecordPermission { result in
                    granted = result
                    semaphore.signal()
                }
                semaphore.wait()
            @unknown default:
                throw AudioSessionError.microphonePermissionDenied
            }
        }

        if !granted {
            throw AudioSessionError.microphonePermissionDenied
        }
    }
}
