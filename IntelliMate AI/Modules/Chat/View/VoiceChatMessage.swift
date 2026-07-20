//
//  VoiceChatMessage.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 20/07/26.
//


import UIKit

/// Local transcript model used only by the voice-call chat UI.
/// Renamed to avoid colliding with the app's existing `ChatMessage` model.
struct VoiceChatMessage {
    enum Role {
        case user
        case assistant
        case system

        var isUser: Bool { self == .user }
    }

    let id = UUID()
    let text: String
    let role: Role
    let timestamp: Date = Date()

    init(text: String, roleString: String?) {
        self.text = text
        switch roleString?.lowercased() {
        case "user", "me":
            self.role = .user
        case "system", "error":
            self.role = .system
        default:
            self.role = .assistant
        }
    }
}

final class ChatMessageCell: UITableViewCell {

    static let reuseIdentifier = "ChatMessageCell"

    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()

    private var bubbleLeading: NSLayoutConstraint!
    private var bubbleTrailing: NSLayoutConstraint!
    private var timeLeading: NSLayoutConstraint!
    private var timeTrailing: NSLayoutConstraint!

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.layer.cornerRadius = 20
        bubbleView.layer.cornerCurve = .continuous
        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOpacity = 0.06
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 2)
        bubbleView.layer.shadowRadius = 4
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        // Readable body text: comfortable size + slightly loosened line spacing.
        messageLabel.font = .systemFont(ofSize: 16, weight: .regular)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)

        timeLabel.font = .systemFont(ofSize: 11, weight: .medium)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)

        let maxWidthConstraint = bubbleView.widthAnchor.constraint(
            lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78
        )
        maxWidthConstraint.priority = .required

        bubbleLeading = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14)
        bubbleTrailing = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14)
        timeLeading = timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 4)
        timeTrailing = timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -4)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            maxWidthConstraint,

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),

            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with message: VoiceChatMessage) {
        // Loosen line spacing a touch so multi-line replies are easier to scan.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        messageLabel.attributedText = NSAttributedString(
            string: message.text,
            attributes: [.paragraphStyle: paragraphStyle]
        )
        timeLabel.text = Self.timeFormatter.string(from: message.timestamp)

        bubbleLeading.isActive = false
        bubbleTrailing.isActive = false
        timeLeading.isActive = false
        timeTrailing.isActive = false
        bubbleView.layer.borderWidth = 0

        switch message.role {
        case .user:
            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            bubbleTrailing.isActive = true
            timeTrailing.isActive = true
            timeLabel.textAlignment = .right

        case .assistant:
            bubbleView.backgroundColor = .secondarySystemBackground
            bubbleView.layer.borderWidth = 1
            bubbleView.layer.borderColor = UIColor.separator.withAlphaComponent(0.5).cgColor
            messageLabel.textColor = .label
            bubbleLeading.isActive = true
            timeLeading.isActive = true
            timeLabel.textAlignment = .left

        case .system:
            bubbleView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
            messageLabel.textColor = .systemRed
            bubbleLeading.isActive = true
            timeLeading.isActive = true
            timeLabel.textAlignment = .left
        }
    }
}
