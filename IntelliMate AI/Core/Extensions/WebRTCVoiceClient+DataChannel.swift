//
//  WebRTCVoiceClient+DataChannel.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 07/07/26.
//

import Foundation
import WebRTC

extension WebRTCVoiceClient: RTCDataChannelDelegate {

    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("dataChannel state = \(dataChannel.readyState.rawValue) label = \(dataChannel.label)")
    }

    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        guard !buffer.isBinary else { return }

        let data = buffer.data

        do {
            let event = try JSONDecoder().decode(AssistantEvent.self, from: data)

            DispatchQueue.main.async {
                if let state = event.state {
                    let mapped = VoiceConnectionState(rawValue: state) ?? .connected
                    self.delegate?.voiceClient(self, didChangeState: mapped)
                }

                if let text = event.text {
                    self.delegate?.voiceClient(self, didReceiveTranscript: text, role: event.role)
                }
            }
        } catch {
            if let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.delegate?.voiceClient(self, didReceiveTranscript: text, role: nil)
                }
            }
        }
    }
}
