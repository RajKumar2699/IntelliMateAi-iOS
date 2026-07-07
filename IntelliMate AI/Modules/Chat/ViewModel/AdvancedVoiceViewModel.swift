//
//  AdvancedVoiceViewModel.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 07/07/26.
//


import Foundation

final class AdvancedVoiceViewModel: NSObject {

    private let client: WebRTCVoiceClient

    var onStateChange: ((VoiceConnectionState) -> Void)?
    var onTranscript: ((String, String?) -> Void)?
    var onError: ((String) -> Void)?

    init(client: WebRTCVoiceClient) {
        self.client = client
        super.init()
        self.client.delegate = self
    }

    func startVoiceCall() {
        client.start()
    }

    func stopVoiceCall() {
        client.stop()
    }
}

extension AdvancedVoiceViewModel: WebRTCVoiceClientDelegate {
    func voiceClient(_ client: WebRTCVoiceClient, didChangeState state: VoiceConnectionState) {
        onStateChange?(state)
    }

    func voiceClient(_ client: WebRTCVoiceClient, didReceiveTranscript text: String, role: String?) {
        onTranscript?(text, role)
    }

    func voiceClient(_ client: WebRTCVoiceClient, didFail error: String) {
        onError?(error)
    }
}
