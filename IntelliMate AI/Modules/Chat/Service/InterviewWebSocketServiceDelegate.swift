//
//  InterviewWebSocketServiceDelegate.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import Foundation

protocol InterviewWebSocketServiceDelegate: AnyObject {
    func didConnectSession(sessionId: String)
    func didRegisterInterviewer(profileId: String)
    func didReceiveTranscript(_ transcript: WSTranscriptMessage)
    func didReceiveAnswer(_ answer: WSAnswerMessage)
    func didReceiveSocketError(_ message: String)
    func didDisconnect()
}

final class InterviewWebSocketService: NSObject {
    weak var delegate: InterviewWebSocketServiceDelegate?

    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    private let decoder = JSONDecoder()

    private let wsURLString = "ws://192.168.1.10:8000/api/v1/interview/ws" // replace with your Mac IP
    private var pendingCandidateProfileId: String?

    func connect(candidateProfileId: String) {
        guard let url = URL(string: wsURLString) else {
            delegate?.didReceiveSocketError("Invalid WebSocket URL")
            return
        }

        pendingCandidateProfileId = candidateProfileId
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
    }

    func sendAudioChunk(_ data: Data) {
        webSocketTask?.send(.data(data)) { [weak self] error in
            if let error {
                DispatchQueue.main.async {
                    self?.delegate?.didReceiveSocketError(error.localizedDescription)
                }
            }
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        DispatchQueue.main.async {
            self.delegate?.didDisconnect()
        }
    }

    private func sendInitPayload() {
        guard let candidateProfileId = pendingCandidateProfileId else { return }

        let payload: [String: String] = ["candidate_profile_id": candidateProfileId]

        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            let json = String(data: data, encoding: .utf8) ?? "{}"

            webSocketTask?.send(.string(json)) { [weak self] error in
                if let error {
                    self?.delegate?.didReceiveSocketError(error.localizedDescription)
                }
            }

            receiveLoop()
        } catch {
            delegate?.didReceiveSocketError(error.localizedDescription)
        }
    }

    private func receiveLoop() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.didReceiveSocketError(error.localizedDescription)
                    self.delegate?.didDisconnect()
                }

            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }

                self.receiveLoop()
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let base = try decoder.decode(WSBaseMessage.self, from: data)

            switch base.type {
            case "session_started":
                let msg = try decoder.decode(WSSessionStarted.self, from: data)
                DispatchQueue.main.async {
                    self.delegate?.didConnectSession(sessionId: msg.sessionId)
                }

            case "interviewer_registered":
                let msg = try decoder.decode(WSInterviewerRegistered.self, from: data)
                DispatchQueue.main.async {
                    self.delegate?.didRegisterInterviewer(profileId: msg.interviewerProfileId)
                }

            case "transcript":
                let msg = try decoder.decode(WSTranscriptMessage.self, from: data)
                DispatchQueue.main.async {
                    self.delegate?.didReceiveTranscript(msg)
                }

            case "answer":
                let msg = try decoder.decode(WSAnswerMessage.self, from: data)
                DispatchQueue.main.async {
                    self.delegate?.didReceiveAnswer(msg)
                }

            case "error":
                let msg = try decoder.decode(WSErrorMessage.self, from: data)
                DispatchQueue.main.async {
                    self.delegate?.didReceiveSocketError(msg.message)
                }

            default:
                break
            }
        } catch {
            DispatchQueue.main.async {
                self.delegate?.didReceiveSocketError("Decode error: \(error.localizedDescription)")
            }
        }
    }
}

extension InterviewWebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        sendInitPayload()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        delegate?.didDisconnect()
    }
}
