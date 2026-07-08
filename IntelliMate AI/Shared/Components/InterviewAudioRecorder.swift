//
//  InterviewAudioRecorder.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 08/07/26.
//


import AVFoundation
import Foundation

protocol InterviewAudioRecorderDelegate: AnyObject {
    func didPrepareEnrollmentFile(url: URL)
    func didFinishEnrollmentRecording(url: URL)
    func didFailAudioRecorder(error: Error)
    func didProduceStreamingAudioChunk(_ data: Data)
}

final class InterviewAudioRecorder: NSObject {
    weak var delegate: InterviewAudioRecorderDelegate?

    private let audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?

    private let audioEngine = AVAudioEngine()
    private let converterOutputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                                      sampleRate: 16000,
                                                      channels: 1,
                                                      interleaved: true)!

    private var streamingStarted = false

    func requestPermission(completion: @escaping (Bool) -> Void) {
        audioSession.requestRecordPermission(completion)
    }

    func startEnrollmentRecording(fileName: String = "candidate_enrollment.m4a") {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)

            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            delegate?.didPrepareEnrollmentFile(url: url)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
        } catch {
            delegate?.didFailAudioRecorder(error: error)
        }
    }

    func stopEnrollmentRecording() {
        audioRecorder?.stop()
    }

    func startStreaming() {
        guard !streamingStarted else { return }
        streamingStarted = true

        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setPreferredSampleRate(16000)
            try audioSession.setPreferredIOBufferDuration(0.02)
            try audioSession.setActive(true)

            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.inputFormat(forBus: 0)

            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
                self?.processBuffer(buffer, inputFormat: inputFormat)
            }

            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            streamingStarted = false
            delegate?.didFailAudioRecorder(error: error)
        }
    }

    func stopStreaming() {
        guard streamingStarted else { return }
        streamingStarted = false
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat) {
        guard let converter = AVAudioConverter(from: inputFormat, to: converterOutputFormat) else { return }

        let frameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * (converterOutputFormat.sampleRate / inputFormat.sampleRate) + 1024)
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: converterOutputFormat, frameCapacity: frameCapacity) else { return }

        var error: NSError?
        var inputProvided = false

        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            if inputProvided {
                outStatus.pointee = .noDataNow
                return nil
            } else {
                inputProvided = true
                outStatus.pointee = .haveData
                return buffer
            }
        }

        converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)

        if let error {
            delegate?.didFailAudioRecorder(error: error)
            return
        }

        guard let channelData = convertedBuffer.int16ChannelData else { return }
        let samples = Int(convertedBuffer.frameLength)
        let data = Data(bytes: channelData.pointee, count: samples * MemoryLayout<Int16>.size)
        delegate?.didProduceStreamingAudioChunk(data)
    }
}

extension InterviewAudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            delegate?.didFinishEnrollmentRecording(url: recorder.url)
        } else {
            delegate?.didFailAudioRecorder(error: NSError(domain: "InterviewAudioRecorder", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Enrollment recording failed"
            ]))
        }
    }
}
