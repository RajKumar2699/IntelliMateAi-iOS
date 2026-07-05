//
//  ATSMeterView.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 05/07/26.
//


import UIKit

final class ATSCircleView: UIView {

    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let scoreLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupLabels()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let lineWidth: CGFloat = 16
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth

        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + CGFloat.pi * 2

        let path = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        backgroundLayer.path = path.cgPath
        backgroundLayer.frame = bounds

        progressLayer.path = path.cgPath
        progressLayer.frame = bounds
    }

    private func setupLayers() {
        backgroundLayer.strokeColor = UIColor.systemGray5.cgColor
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = 16

        progressLayer.strokeColor = UIColor.systemGreen.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 16
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0

        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)
    }

    private func setupLabels() {
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.font = .systemFont(ofSize: 42, weight: .bold)
        scoreLabel.textAlignment = .center
        scoreLabel.text = "0"

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.text = "ATS Score"

        addSubview(scoreLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            scoreLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            scoreLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),

            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 4)
        ])
    }

    func update(score: Int) {
        let clamped = max(0, min(score, 100))
        scoreLabel.text = "\(clamped)"

        let color: UIColor
        switch clamped {
        case 0..<50: color = .systemRed
        case 50..<75: color = .systemOrange
        default: color = .systemGreen
        }

        progressLayer.strokeColor = color.cgColor

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progressLayer.strokeEnd
        animation.toValue = CGFloat(clamped) / 100
        animation.duration = 0.8
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        progressLayer.strokeEnd = CGFloat(clamped) / 100
        progressLayer.add(animation, forKey: "progress")
    }
}
