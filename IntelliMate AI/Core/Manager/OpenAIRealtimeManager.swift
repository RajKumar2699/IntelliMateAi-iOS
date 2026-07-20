//
//  OpenAIRealtimeManager.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import Foundation
import AVFoundation
import WebRTC

protocol OpenAIRealtimeManagerDelegate: AnyObject {
    func realtimeManagerDidConnect(_ manager: OpenAIRealtimeManager)
    func realtimeManagerDidDisconnect(_ manager: OpenAIRealtimeManager)
    func realtimeManager(_ manager: OpenAIRealtimeManager, didReceiveTranscript text: String, role: String?)
    func realtimeManager(_ manager: OpenAIRealtimeManager, didFail error: Error)
}

private struct SessionUpdateEvent: Encodable {
    let type = "session.update"
    let session: SessionConfig
}

private struct SessionConfig: Encodable {
    let type = "realtime"
    let output_modalities: [String]
    let audio: AudioConfig
}

private struct AudioConfig: Encodable {
    let input: AudioInputConfig
}

private struct AudioInputConfig: Encodable {
    let turn_detection: TurnDetectionConfig
    let transcription: TranscriptionConfig
}

private struct TurnDetectionConfig: Encodable {
    let type: String
    let threshold: Double
    let prefix_padding_ms: Int
    let silence_duration_ms: Int
    let create_response: Bool
}

private struct TranscriptionConfig: Encodable {
    let model: String
}

final class OpenAIRealtimeManager: NSObject {
    weak var delegate: OpenAIRealtimeManagerDelegate?

    private let backendAPI: BackendAPIService
    private var factory: RTCPeerConnectionFactory!
    private var peerConnection: RTCPeerConnection?
    private var audioTrack: RTCAudioTrack?
    private var localAudioSource: RTCAudioSource?
    private var remoteAudioTrack: RTCAudioTrack?
    private var dataChannel: RTCDataChannel?

    private(set) var isConnected = false
    private(set) var isSpeakerMuted = false
    private(set) var isMicMuted = false

    init(backendAPI: BackendAPIService) {
        self.backendAPI = backendAPI
        super.init()
        RTCInitializeSSL()
        self.factory = RTCPeerConnectionFactory()
    }

    deinit {
        RTCCleanupSSL()
    }

    func connect(languageHint: String? = nil, voice: String? = nil) async throws {
        try AudioSessionManager.shared.configureForVoiceChat()

        let sessionInfo = try await backendAPI.createRealtimeSession(
            languageHint: languageHint,
            voice: voice
        )

        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        ]

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
        )

        guard let pc = factory.peerConnection(with: config, constraints: constraints, delegate: self) else {
            throw NSError(
                domain: "OpenAIRealtimeManager",
                code: -200,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create RTCPeerConnection"]
            )
        }
        self.peerConnection = pc

        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let source = factory.audioSource(with: audioConstraints)
        self.localAudioSource = source

        let track = factory.audioTrack(with: source, trackId: "mic-audio")
        self.audioTrack = track
        track.isEnabled = !isMicMuted
        pc.add(track, streamIds: ["stream0"])

        let dcConfig = RTCDataChannelConfiguration()
        dcConfig.isOrdered = true

        guard let dc = pc.dataChannel(forLabel: "oai-events", configuration: dcConfig) else {
            throw NSError(
                domain: "OpenAIRealtimeManager",
                code: -201,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create data channel"]
            )
        }
        dc.delegate = self
        self.dataChannel = dc

        let offer = try await createOffer(peerConnection: pc)
        try await setLocalDescription(peerConnection: pc, sdp: offer)

        let answerSDP = try await postOfferToOpenAI(
            offerSDP: offer.sdp,
            clientSecret: sessionInfo.clientSecret
        )

        let remoteDescription = RTCSessionDescription(type: .answer, sdp: answerSDP)
        try await setRemoteDescription(peerConnection: pc, sdp: remoteDescription)

        AudioSessionManager.shared.forceSpeakerRetry()
        isConnected = true
    }

    func disconnect() {
        dataChannel?.close()
        peerConnection?.close()
        peerConnection = nil
        audioTrack = nil
        localAudioSource = nil
        remoteAudioTrack = nil
        dataChannel = nil

        if isConnected {
            delegate?.realtimeManagerDidDisconnect(self)
        }
        isConnected = false
    }

    func sendText(_ text: String) {
        guard dataChannel != nil else { return }

        sendEvent([
            "type": "conversation.item.create",
            "item": [
                "type": "message",
                "role": "user",
                "content": [["type": "input_text", "text": text]]
            ]
        ])
        sendEvent(["type": "response.create"])
    }

    func setSpeakerMuted(_ muted: Bool) {
        isSpeakerMuted = muted
        remoteAudioTrack?.isEnabled = !muted
    }

    func setMicMuted(_ muted: Bool) {
        isMicMuted = muted
        audioTrack?.isEnabled = !muted
    }

    private func sendSessionUpdate() {
        let event = SessionUpdateEvent(
            session: SessionConfig(
                output_modalities: ["audio"],
                audio: AudioConfig(
                    input: AudioInputConfig(
                        turn_detection: TurnDetectionConfig(
                            type: "server_vad",
                            threshold: 0.6,
                            prefix_padding_ms: 300,
                            silence_duration_ms: 500,
                            create_response: true
                        ),
                        transcription: TranscriptionConfig(model: "whisper-1")
                    )
                )
            )
        )
        sendCodableEvent(event)
    }

    private func sendEvent(_ event: [String: Any]) {
        guard let dataChannel else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: event),
              let json = String(data: data, encoding: .utf8),
              let payload = json.data(using: .utf8) else { return }

        dataChannel.sendData(RTCDataBuffer(data: payload, isBinary: false))
    }

    private func sendCodableEvent<T: Encodable>(_ event: T) {
        guard let dataChannel else { return }
        guard let data = try? JSONEncoder().encode(event) else { return }
        dataChannel.sendData(RTCDataBuffer(data: data, isBinary: false))
    }

    private func postOfferToOpenAI(offerSDP: String, clientSecret: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/realtime/calls") else {
            throw NSError(domain: "OpenAIRealtimeManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid OpenAI URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(clientSecret)", forHTTPHeaderField: "Authorization")
        request.httpBody = offerSDP.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIRealtimeManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid OpenAI response"])
        }
        guard 200..<300 ~= http.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown OpenAI error"
            throw NSError(domain: "OpenAIRealtimeManager", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        guard let sdp = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "OpenAIRealtimeManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid SDP answer"])
        }
        return sdp
    }

    private func createOffer(peerConnection: RTCPeerConnection) async throws -> RTCSessionDescription {
        try await withCheckedThrowingContinuation { continuation in
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            peerConnection.offer(for: constraints) { sdp, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let sdp {
                    continuation.resume(returning: sdp)
                } else {
                    continuation.resume(throwing: NSError(domain: "OpenAIRealtimeManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "Offer creation failed"]))
                }
            }
        }
    }

    private func setLocalDescription(peerConnection: RTCPeerConnection, sdp: RTCSessionDescription) async throws {
        try await withCheckedThrowingContinuation { continuation in
            peerConnection.setLocalDescription(sdp) { error in
                error == nil ? continuation.resume(returning: ()) : continuation.resume(throwing: error!)
            }
        }
    }

    private func setRemoteDescription(peerConnection: RTCPeerConnection, sdp: RTCSessionDescription) async throws {
        try await withCheckedThrowingContinuation { continuation in
            peerConnection.setRemoteDescription(sdp) { error in
                error == nil ? continuation.resume(returning: ()) : continuation.resume(throwing: error!)
            }
        }
    }

    private func handleIncomingEventText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "response.output_audio_transcript.done", "response.audio_transcript.done":
            let transcript = json["transcript"] as? String ?? ""
            if !transcript.isEmpty {
                delegate?.realtimeManager(self, didReceiveTranscript: transcript, role: "assistant")
            }

        case "conversation.item.input_audio_transcription.completed":
            let transcript = json["transcript"] as? String ?? ""
            if !transcript.isEmpty {
                delegate?.realtimeManager(self, didReceiveTranscript: transcript, role: "user")
            }

        case "error":
            let message = (json["error"] as? [String: Any])?["message"] as? String ?? "Unknown realtime error"
            delegate?.realtimeManager(
                self,
                didFail: NSError(
                    domain: "OpenAIRealtimeManager",
                    code: -100,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            )

        default:
            break
        }
    }
}

extension OpenAIRealtimeManager: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams: [RTCMediaStream]) {
        if let track = rtpReceiver.track as? RTCAudioTrack {
            remoteAudioTrack = track
            remoteAudioTrack?.isEnabled = !isSpeakerMuted
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCPeerConnectionState) {
        switch stateChanged {
        case .connected:
            delegate?.realtimeManagerDidConnect(self)
        case .disconnected, .closed, .failed:
            delegate?.realtimeManagerDidDisconnect(self)
        default:
            break
        }
    }
}

extension OpenAIRealtimeManager: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        if dataChannel.readyState == .open {
            sendSessionUpdate()
        }
    }

    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        guard let text = String(data: buffer.data, encoding: .utf8) else { return }
        handleIncomingEventText(text)
    }
}
