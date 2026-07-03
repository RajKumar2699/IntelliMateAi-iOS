//
//  ChatInputView.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import UIKit

final class ChatInputView: UIView, UITextViewDelegate {
    var onSendTapped: ((String) -> Void)?

    private let blurView: UIVisualEffectView = {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blur.layer.cornerRadius = 22
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        blur.translatesAutoresizingMaskIntoConstraints = false
        return blur
    }()

    private let textView: UITextView = {
        let view = UITextView()
        view.font = .preferredFont(forTextStyle: .body)
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = UIEdgeInsets(top: 12, left: 2, bottom: 12, right: 2)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Ask IntelliMate anything..."
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .placeholderText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 22
        button.layer.cornerCurve = .continuous
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        return button
    }()

    private var textViewHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func clearText() {
        textView.text = ""
        placeholderLabel.isHidden = false
        updateTextViewHeight()
    }

    private func setupUI() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(blurView)
        blurView.contentView.addSubview(textView)
        blurView.contentView.addSubview(placeholderLabel)
        addSubview(sendButton)

        textView.delegate = self

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            blurView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),

            sendButton.leadingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: 12),
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            sendButton.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),

            textView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 2),
            textView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -12),
            textView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -2),

            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 6),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor)
        ])

        textViewHeightConstraint = textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        textViewHeightConstraint?.isActive = true
    }

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
    }

    @objc private func sendTapped() {
        animateSendButton()
        let text = textView.text ?? ""
        onSendTapped?(text)
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateTextViewHeight()
    }

    private func updateTextViewHeight() {
        let height = min(max(textView.calculatedHeight(), 44), 120)
        textViewHeightConstraint?.constant = height
        layoutIfNeeded()
    }

    private func animateSendButton() {
        UIView.animate(withDuration: 0.12, animations: {
            self.sendButton.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }) { _ in
            UIView.animate(withDuration: 0.16) {
                self.sendButton.transform = .identity
            }
        }
    }
}
