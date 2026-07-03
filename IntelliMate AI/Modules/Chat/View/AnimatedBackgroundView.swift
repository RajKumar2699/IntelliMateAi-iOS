//
//  AnimatedBackgroundView.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import UIKit

final class AnimatedBackgroundView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let orbLayer1 = CAShapeLayer()
    private let orbLayer2 = CAShapeLayer()
    private let orbLayer3 = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        setupLayers()
        startAnimating()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        updateOrbPaths()
    }

    private func setupLayers() {
        gradientLayer.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.secondarySystemBackground.cgColor,
            UIColor.systemGroupedBackground.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradientLayer)

        [orbLayer1, orbLayer2, orbLayer3].forEach {
            $0.fillColor = UIColor.clear.cgColor
            layer.addSublayer($0)
        }

        orbLayer1.fillColor = UIColor.systemBlue.withAlphaComponent(0.10).cgColor
        orbLayer2.fillColor = UIColor.systemTeal.withAlphaComponent(0.08).cgColor
        orbLayer3.fillColor = UIColor.systemIndigo.withAlphaComponent(0.06).cgColor
    }

    private func updateOrbPaths() {
        orbLayer1.path = UIBezierPath(ovalIn: CGRect(x: -40, y: 80, width: 220, height: 220)).cgPath
        orbLayer2.path = UIBezierPath(ovalIn: CGRect(x: bounds.width - 180, y: 140, width: 200, height: 200)).cgPath
        orbLayer3.path = UIBezierPath(ovalIn: CGRect(x: bounds.midX - 80, y: 20, width: 180, height: 180)).cgPath
    }

    private func startAnimating() {
        animate(layer: orbLayer1, x: 18, y: -12, duration: 10)
        animate(layer: orbLayer2, x: -16, y: 20, duration: 12)
        animate(layer: orbLayer3, x: 10, y: 14, duration: 14)
    }

    private func animate(layer: CALayer, x: CGFloat, y: CGFloat, duration: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath: "transform.translation")
        animation.fromValue = NSValue(cgSize: .zero)
        animation.toValue = NSValue(cgSize: CGSize(width: x, height: y))
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "floating")
    }
}