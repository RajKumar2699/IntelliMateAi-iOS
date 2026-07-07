//
//  OrbView.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 06/07/26.
//


import UIKit

final class OrbView: UIView {
    enum State {
        case idle
        case listening
        case thinking
        case speaking
    }

    private let glowLayer = CAGradientLayer()
    private let coreView = UIView()
    private let pulseLayer = CAShapeLayer()

    private var displayLink: CADisplayLink?
    private var phase: CGFloat = 0
    private var audioLevel: CGFloat = 0.08
    private(set) var currentState: State = .idle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        startAnimating()
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handlePower(_:)),
//            name: .voiceOrbPowerDidChange,
//            object: nil
//        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glowLayer.frame = bounds
        glowLayer.cornerRadius = bounds.width / 2

        coreView.frame = bounds.insetBy(dx: 34, dy: 34)
        coreView.layer.cornerRadius = coreView.bounds.width / 2

        pulseLayer.frame = bounds
        pulseLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: 8, dy: 8)).cgPath
    }

    private func setupUI() {
        backgroundColor = .clear

        glowLayer.colors = [
            UIColor(red: 0.22, green: 0.73, blue: 1.00, alpha: 1).cgColor,
            UIColor(red: 0.49, green: 0.37, blue: 1.00, alpha: 1).cgColor,
            UIColor(red: 0.12, green: 0.89, blue: 0.89, alpha: 1).cgColor
        ]
        glowLayer.startPoint = CGPoint(x: 0, y: 0)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(glowLayer)

        pulseLayer.fillColor = UIColor.clear.cgColor
        pulseLayer.strokeColor = UIColor.white.withAlphaComponent(0.16).cgColor
        pulseLayer.lineWidth = 1.2
        layer.addSublayer(pulseLayer)

        coreView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        coreView.layer.borderWidth = 1
        coreView.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        addSubview(coreView)

        layer.shadowColor = UIColor.systemBlue.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 36
        layer.shadowOffset = .zero
    }

    func setState(_ state: State) {
        currentState = state

        switch state {
        case .idle:
            layer.shadowOpacity = 0.20
        case .listening:
            layer.shadowOpacity = 0.48
        case .thinking:
            layer.shadowOpacity = 0.32
        case .speaking:
            layer.shadowOpacity = 0.58
        }
    }

    private func startAnimating() {
        displayLink = CADisplayLink(target: self, selector: #selector(step))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc
    private func step() {
        phase += 0.045

        let scale: CGFloat
        switch currentState {
        case .idle:
            scale = 1.0
        case .listening:
            scale = 1.0 + (audioLevel * 0.18)
        case .thinking:
            scale = 1.04 + sin(phase) * 0.03
        case .speaking:
            scale = 1.07 + sin(phase * 1.7) * 0.05
        }

        transform = CGAffineTransform(scaleX: scale, y: scale)

        if glowLayer.animation(forKey: "rotation") == nil {
            let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotation.toValue = CGFloat.pi * 2
            rotation.duration = 9
            rotation.repeatCount = .infinity
            rotation.isRemovedOnCompletion = false
            glowLayer.add(rotation, forKey: "rotation")
        }
    }

    @objc
    private func handlePower(_ note: Notification) {
        guard let value = note.object as? CGFloat else { return }
        audioLevel = value
    }
}
