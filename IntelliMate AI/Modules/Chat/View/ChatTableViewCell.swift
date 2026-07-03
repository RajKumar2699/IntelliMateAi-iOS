//
//  ChatTableViewCell.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import UIKit

final class ChatTableViewCell: UITableViewCell {
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let stackContainer = UIView()

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
    }

    func configure(with message: ChatMessage) {
        messageLabel.text = message.text

        switch message.sender {
        case .user:
            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
            bubbleView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner
            ]

        case .ai:
            bubbleView.backgroundColor = .secondarySystemGroupedBackground
            messageLabel.textColor = .label
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
            bubbleView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        }
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        stackContainer.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 20
        bubbleView.layer.cornerCurve = .continuous

        messageLabel.numberOfLines = 0
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackContainer)
        stackContainer.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)

        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: stackContainer.leadingAnchor)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: stackContainer.trailingAnchor)

        NSLayoutConstraint.activate([
            stackContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stackContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            stackContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            bubbleView.topAnchor.constraint(equalTo: stackContainer.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: stackContainer.bottomAnchor),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: stackContainer.widthAnchor, multiplier: 0.78),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }
}
