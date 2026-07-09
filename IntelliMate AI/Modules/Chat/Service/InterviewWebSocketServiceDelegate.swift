import Foundation

protocol InterviewWebSocketServiceDelegate: AnyObject {
    func didConnectSession(sessionId: String)
    func didRegisterInterviewer(profileId: String)
    func didReceiveTranscript(_ transcript: WSTranscriptMessage)
    func didReceiveAnswer(_ answer: WSAnswerMessage)
    func didReceiveDroppedUtterance(reason: String, score: Double)
    func didReceiveSocketError(_ message: String)
    func didDisconnect()
}

final class InterviewWebSocketService {
    weak var delegate: InterviewWebSocketServiceDelegate?

    private let baseURL = "ws://10.83.230.123:8000/api/v1/interview/ws"
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?

    func connect(candidateProfileId: String) {
        guard let url = URL(string: baseURL) else {
            delegate?.didReceiveSocketError("Invalid websocket URL")
            return
        }

        let session = URLSession(configuration: .default)
        self.session = session

        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()

        let initPayload: [String: String] = [
            "candidate_profile_id": candidateProfileId
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: initPayload)
            guard let text = String(data: data, encoding: .utf8) else {
                delegate?.didReceiveSocketError("Failed to encode init payload")
                return
            }

            task.send(.string(text)) { [weak self] error in
                guard let self else { return }

                if let error {
                    self.delegate?.didReceiveSocketError(error.localizedDescription)
                    return
                }

                self.receiveLoop()
            }
        } catch {
            delegate?.didReceiveSocketError(error.localizedDescription)
        }
    }

    func sendAudioChunk(_ data: Data) -> Bool {
        guard let webSocketTask else { return false }

        webSocketTask.send(.data(data)) { [weak self] error in
            if let error {
                self?.delegate?.didReceiveSocketError(error.localizedDescription)
            }
        }

        return true
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        session?.invalidateAndCancel()
        webSocketTask = nil
        session = nil
        delegate?.didDisconnect()
    }

    private func receiveLoop() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                self.delegate?.didReceiveSocketError(error.localizedDescription)
                self.delegate?.didDisconnect()

            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleIncomingText(text)

                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleIncomingText(text)
                    }

                @unknown default:
                    break
                }

                self.receiveLoop()
            }
        }
    }

    private func handleIncomingText(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let base = try JSONDecoder().decode(WSBaseMessage.self, from: data)

            switch base.type {
            case "session_started":
                let model = try JSONDecoder().decode(WSSessionStarted.self, from: data)
                delegate?.didConnectSession(sessionId: model.sessionId)

            case "interviewer_registered":
                let model = try JSONDecoder().decode(WSInterviewerRegistered.self, from: data)
                delegate?.didRegisterInterviewer(profileId: model.interviewerProfileId)

            case "transcript":
                let model = try JSONDecoder().decode(WSTranscriptMessage.self, from: data)
                delegate?.didReceiveTranscript(model)

            case "answer":
                let model = try JSONDecoder().decode(WSAnswerMessage.self, from: data)
                delegate?.didReceiveAnswer(model)

            case "debug_dropped":
                let model = try JSONDecoder().decode(WSDroppedMessage.self, from: data)
                delegate?.didReceiveDroppedUtterance(reason: model.reason, score: model.score)

            case "error":
                let model = try JSONDecoder().decode(WSErrorMessage.self, from: data)
                delegate?.didReceiveSocketError(model.message)

            default:
                break
            }
        } catch {
            delegate?.didReceiveSocketError("Failed to decode socket message: \(error.localizedDescription)")
        }
    }
}
