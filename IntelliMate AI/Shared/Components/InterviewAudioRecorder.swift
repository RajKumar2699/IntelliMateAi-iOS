//
//  InterviewAudioRecorder.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import Foundation
import AVFoundation

protocol InterviewAudioRecorderDelegate: AnyObject {
    func didPrepareEnrollmentFile(url: URL)
    func didFinishEnrollmentRecording(url: URL)
    func didFailAudioRecorder(error: Error)
    func didProduceStreamingAudioChunk(_ data: Data)
}

final class InterviewAudioRecorder: NSObject {
    weak var delegate: InterviewAudioRecorderDelegate?

    private var enrollmentRecorder: AVAudioRecorder?
    private let audioEngine = AVAudioEngine()
    private let converterQueue = DispatchQueue(label: "interview.audio.converter")
    private var isStreaming = false
    private var currentEnrollmentURL: URL?

    func requestPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }

    func startEnrollmentRecording(fileName: String) {
        stopStreaming()
        enrollmentRecorder?.stop()
        enrollmentRecorder = nil

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setPreferredSampleRate(16000)
            try session.setActive(true, options: [])

            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
            currentEnrollmentURL = url

            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true

            guard recorder.prepareToRecord() else {
                throw NSError(
                    domain: "InterviewAudioRecorder",
                    code: -1000,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to prepare enrollment recorder"]
                )
            }

            delegate?.didPrepareEnrollmentFile(url: url)

            guard recorder.record() else {
                throw NSError(
                    domain: "InterviewAudioRecorder",
                    code: -1001,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to start enrollment recording"]
                )
            }

            enrollmentRecorder = recorder
        } catch {
            delegate?.didFailAudioRecorder(error: error)
        }
    }

    func stopEnrollmentRecording() {
        guard let recorder = enrollmentRecorder, recorder.isRecording else { return }
        recorder.stop()
    }

    func startStreaming() {
        guard !isStreaming else { return }

        enrollmentRecorder?.stop()
        enrollmentRecorder = nil

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setPreferredSampleRate(16000)
            try session.setPreferredIOBufferDuration(0.064)
            try session.setActive(true, options: [])

            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.inputFormat(forBus: 0)

            guard let targetFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: 16000,
                channels: 1,
                interleaved: true
            ) else {
                throw NSError(
                    domain: "InterviewAudioRecorder",
                    code: -1002,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to create target audio format"]
                )
            }

            inputNode.removeTap(onBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
                guard let self else { return }

                self.converterQueue.async {
                    guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
                        return
                    }

                    let ratio = targetFormat.sampleRate / inputFormat.sampleRate
                    let frameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024

                    guard let convertedBuffer = AVAudioPCMBuffer(
                        pcmFormat: targetFormat,
                        frameCapacity: frameCapacity
                    ) else {
                        return
                    }

                    var conversionError: NSError?
                    var didProvideInput = false

                    let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                        if didProvideInput {
                            outStatus.pointee = .noDataNow
                            return nil
                        }
                        didProvideInput = true
                        outStatus.pointee = .haveData
                        return buffer
                    }

                    converter.convert(to: convertedBuffer, error: &conversionError, withInputFrom: inputBlock)

                    if let conversionError {
                        DispatchQueue.main.async {
                            self.delegate?.didFailAudioRecorder(error: conversionError)
                        }
                        return
                    }

                    guard let channelData = convertedBuffer.int16ChannelData else { return }
                    let frameLength = Int(convertedBuffer.frameLength)
                    guard frameLength > 0 else { return }

                    let data = Data(bytes: channelData[0], count: frameLength * MemoryLayout<Int16>.size)

                    DispatchQueue.main.async {
                        self.delegate?.didProduceStreamingAudioChunk(data)
                    }
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            isStreaming = true
        } catch {
            delegate?.didFailAudioRecorder(error: error)
        }
    }

    func stopStreaming() {
        guard isStreaming else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isStreaming = false
    }
}

extension InterviewAudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        defer {
            enrollmentRecorder = nil
        }

        guard flag, let url = currentEnrollmentURL else {
            delegate?.didFailAudioRecorder(error: NSError(
                domain: "InterviewAudioRecorder",
                code: -1003,
                userInfo: [NSLocalizedDescriptionKey: "Enrollment recording failed"]
            ))
            return
        }

        delegate?.didFinishEnrollmentRecording(url: url)
    }
}
