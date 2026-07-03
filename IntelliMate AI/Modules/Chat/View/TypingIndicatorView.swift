//
//  TypingIndicatorView.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import UIKit

final class TypingIndicatorView: UIView {
    private let bubbleView = UIView()
    private let dotsStack = UIStackView()
    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        isHidden = true
        alpha = 0
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setVisible(_ visible: Bool) {
        if visible {
            guard isHidden || alpha == 0 else { return }

            isHidden = false
            alpha = 0
            startAnimating()
            bubbleView.transform = CGAffineTransform(translationX: 0, y: 6)

            UIView.animate(withDuration: 0.22) {
                self.alpha = 1
                self.bubbleView.transform = .identity
            }
        } else {
            guard !isHidden else { return }

            UIView.animate(withDuration: 0.18, animations: {
                self.alpha = 0
            }) { _ in
                self.isHidden = true
                self.stopAnimating()
            }
        }
    }

    private func setupUI() {
        backgroundColor = .clear

        bubbleView.backgroundColor = .secondarySystemGroupedBackground
        bubbleView.layer.cornerRadius = 18
        bubbleView.layer.cornerCurve = .continuous
        bubbleView.translatesAutoresizingMaskIntoConstraints = false

        dotsStack.axis = .horizontal
        dotsStack.spacing = 6
        dotsStack.alignment = .center
        dotsStack.distribution = .fillEqually
        dotsStack.translatesAutoresizingMaskIntoConstraints = false

        [dot1, dot2, dot3].forEach {
            $0.backgroundColor = .tertiaryLabel
            $0.layer.cornerRadius = 4
            $0.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $0.widthAnchor.constraint(equalToConstant: 8),
                $0.heightAnchor.constraint(equalToConstant: 8)
            ])
            dotsStack.addArrangedSubview($0)
        }

        addSubview(bubbleView)
        bubbleView.addSubview(dotsStack)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: topAnchor),
            bubbleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bubbleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: bottomAnchor),

            dotsStack.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            dotsStack.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            dotsStack.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            dotsStack.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }

    private func startAnimating() {
        stopAnimating()
        animate(dot: dot1, delay: 0)
        animate(dot: dot2, delay: 0.2)
        animate(dot: dot3, delay: 0.4)
    }

    private func stopAnimating() {
        [dot1, dot2, dot3].forEach {
            $0.layer.removeAllAnimations()
            $0.transform = .identity
            $0.alpha = 1
        }
    }

    private func animate(dot: UIView, delay: TimeInterval) {
        let position = CABasicAnimation(keyPath: "transform.translation.y")
        position.fromValue = 0
        position.toValue = -4
        position.duration = 0.35
        position.autoreverses = true
        position.repeatCount = .infinity
        position.beginTime = CACurrentMediaTime() + delay
        position.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 0.4
        opacity.toValue = 1
        opacity.duration = 0.35
        opacity.autoreverses = true
        opacity.repeatCount = .infinity
        opacity.beginTime = CACurrentMediaTime() + delay
        opacity.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        dot.layer.add(position, forKey: "bounce")
        dot.layer.add(opacity, forKey: "fade")
    }
}
