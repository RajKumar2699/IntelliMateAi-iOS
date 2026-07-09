//
//  FeedAnswerCell.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 09/07/26.
//


import UIKit

final class FeedAnswerCell: UITableViewCell {
    static let reuseId = "FeedAnswerCell"

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let questionLabel = UILabel()
    private let answerLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = Theme.successSoft
        cardView.layer.cornerRadius = 16
        cardView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Suggested Answer"
        titleLabel.font = .boldSystemFont(ofSize: 14)
        titleLabel.textColor = Theme.success
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        questionLabel.font = .systemFont(ofSize: 13)
        questionLabel.textColor = Theme.textSecondary
        questionLabel.numberOfLines = 0
        questionLabel.translatesAutoresizingMaskIntoConstraints = false

        answerLabel.font = .systemFont(ofSize: 16)
        answerLabel.textColor = Theme.textPrimary
        answerLabel.numberOfLines = 0
        answerLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(questionLabel)
        cardView.addSubview(answerLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            questionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            questionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            questionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            answerLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 10),
            answerLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            answerLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            answerLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(question: String, answer: String) {
        questionLabel.text = "Q: \(question)"
        answerLabel.text = answer
    }
}
