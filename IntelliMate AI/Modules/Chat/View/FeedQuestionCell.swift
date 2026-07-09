//
//  FeedQuestionCell.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 09/07/26.
//


import UIKit

final class FeedQuestionCell: UITableViewCell {
    static let reuseId = "FeedQuestionCell"

    private let bubbleView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.backgroundColor = Theme.cardBackground
        bubbleView.layer.cornerRadius = 16
        bubbleView.addCardShadow()

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = Theme.accent
        titleLabel.text = "Interviewer"

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = Theme.textPrimary
        messageLabel.numberOfLines = 0

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(titleLabel)
        bubbleView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),

            titleLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(text: String) {
        messageLabel.text = text
    }
}
