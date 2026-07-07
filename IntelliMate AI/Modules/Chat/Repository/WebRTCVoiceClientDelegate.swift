//
//  WebRTCVoiceClientDelegate.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 07/07/26.
//


import Foundation
import AVFoundation
import WebRTC

protocol WebRTCVoiceClientDelegate: AnyObject {
    func voiceClient(_ client: WebRTCVoiceClient, didChangeState state: VoiceConnectionState)
    func voiceClient(_ client: WebRTCVoiceClient, didReceiveTranscript text: String, role: String?)
    func voiceClient(_ client: WebRTCVoiceClient, didFail error: String)
}

final class WebRTCVoiceClient: NSObject {

    weak var delegate: WebRTCVoiceClientDelegate?

    let signalingBaseURL: URL
    let factory: RTCPeerConnectionFactory
    var peerConnection: RTCPeerConnection?
    var localAudioTrack: RTCAudioTrack?
    var assistantDataChannel: RTCDataChannel?
    var sessionId: String?

    init(signalingBaseURL: URL) {
        self.signalingBaseURL = signalingBaseURL

        RTCInitializeSSL()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        self.factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)

        super.init()
    }

    deinit {
        RTCCleanupSSL()
    }

    func start() {
        delegate?.voiceClient(self, didChangeState: .connecting)

        configureAudioSession()
        createPeerConnection()
        createLocalAudioTrack()
        createDataChannel()
        createOffer()
    }

    func stop() {
        assistantDataChannel?.close()
        assistantDataChannel = nil
        peerConnection?.close()
        peerConnection = nil
        localAudioTrack = nil
        sessionId = nil

        delegate?.voiceClient(self, didChangeState: .disconnected)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playAndRecord,
                                    mode: .videoChat,
                                    options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try session.setPreferredSampleRate(48000)
            try session.setPreferredIOBufferDuration(0.02)
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true, options: [])
        } catch {
            delegate?.voiceClient(self, didFail: "Audio session error: \(error.localizedDescription)")
        }
    }

    private func createPeerConnection() {
        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        ]

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
        )

        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)
    }

    private func createLocalAudioTrack() {
        guard let peerConnection else { return }

        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = factory.audioSource(with: audioConstraints)
        let track = factory.audioTrack(with: audioSource, trackId: "local-audio-track")
        localAudioTrack = track

        peerConnection.add(track, streamIds: ["ai-stream"])
    }

    private func createDataChannel() {
        guard let peerConnection else { return }

        let config = RTCDataChannelConfiguration()
        config.isOrdered = true

        let channel = peerConnection.dataChannel(forLabel: "assistant-status", configuration: config)
        channel?.delegate = self
        assistantDataChannel = channel
    }

    private func createOffer() {
        guard let peerConnection else { return }

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "false"
            ],
            optionalConstraints: nil
        )

        peerConnection.offer(for: constraints) { [weak self] sdp, error in
            guard let self else { return }

            if let error {
                self.delegate?.voiceClient(self, didFail: "Offer creation failed: \(error.localizedDescription)")
                self.delegate?.voiceClient(self, didChangeState: .failed)
                return
            }

            guard let sdp else {
                self.delegate?.voiceClient(self, didFail: "Offer creation returned nil SDP")
                self.delegate?.voiceClient(self, didChangeState: .failed)
                return
            }

            self.peerConnection?.setLocalDescription(sdp) { setLocalError in
                if let setLocalError {
                    self.delegate?.voiceClient(self, didFail: "Set local SDP failed: \(setLocalError.localizedDescription)")
                    self.delegate?.voiceClient(self, didChangeState: .failed)
                    return
                }

                self.sendOfferToBackend(sdp: sdp)
            }
        }
    }

    private func sendOfferToBackend(sdp: RTCSessionDescription) {
        let endpoint = signalingBaseURL.appendingPathComponent("api/v1/webrtc/offer")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = WebRTCOfferRequest(
            sdp: sdp.sdp,
            type: sdpTypeString(from: sdp.type)
        )

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            delegate?.voiceClient(self, didFail: "Offer encoding failed: \(error.localizedDescription)")
            delegate?.voiceClient(self, didChangeState: .failed)
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async {
                    self.delegate?.voiceClient(self, didFail: "Offer request failed: \(error.localizedDescription)")
                    self.delegate?.voiceClient(self, didChangeState: .failed)
                }
                return
            }

            guard let data else {
                DispatchQueue.main.async {
                    self.delegate?.voiceClient(self, didFail: "No response data from backend")
                    self.delegate?.voiceClient(self, didChangeState: .failed)
                }
                return
            }

            do {
                let answer = try JSONDecoder().decode(WebRTCAnswerResponse.self, from: data)
                self.sessionId = answer.session_id

                let remoteSDP = RTCSessionDescription(type: .answer, sdp: answer.sdp)

                self.peerConnection?.setRemoteDescription(remoteSDP) { error in
                    DispatchQueue.main.async {
                        if let error {
                            self.delegate?.voiceClient(self, didFail: "Set remote SDP failed: \(error.localizedDescription)")
                            self.delegate?.voiceClient(self, didChangeState: .failed)
                        } else {
                            self.delegate?.voiceClient(self, didChangeState: .connected)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.delegate?.voiceClient(self, didFail: "Answer decode failed: \(error.localizedDescription)")
                    self.delegate?.voiceClient(self, didChangeState: .failed)
                }
            }
        }.resume()
    }

    private func sdpTypeString(from type: RTCSdpType) -> String {
        switch type {
        case .offer:
            return "offer"
        case .prAnswer:
            return "pranswer"
        case .answer:
            return "answer"
        case .rollback:
            return "rollback"
        @unknown default:
            return "offer"
        }
    }
}
