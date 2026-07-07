//
//  WebRTCVoiceClient+Delegates.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 07/07/26.
//

import Foundation
import WebRTC

extension WebRTCVoiceClient: RTCPeerConnectionDelegate {

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("signalingState = \(stateChanged.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("didAdd stream")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("didRemove stream")
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnectionShouldNegotiate")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("iceConnectionState = \(newState.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("iceGatheringState = \(newState.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("generated ICE candidate")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("didRemove candidates")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen remoteDataChannel: RTCDataChannel) {
        print("didOpen remote data channel: \(remoteDataChannel.label)")
        self.assistantDataChannel = remoteDataChannel
        self.assistantDataChannel?.delegate = self
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange state: RTCPeerConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.delegate?.voiceClient(self, didChangeState: .connected)
            case .disconnected, .closed:
                self.delegate?.voiceClient(self, didChangeState: .disconnected)
            case .failed:
                self.delegate?.voiceClient(self, didChangeState: .failed)
            default:
                break
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
        print("didStartReceivingOn transceiver")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams: [RTCMediaStream]) {
        print("didAdd rtpReceiver track kind = \(rtpReceiver.track?.kind ?? "unknown")")
    }
}
