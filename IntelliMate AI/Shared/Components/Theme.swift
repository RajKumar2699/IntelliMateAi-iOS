//
//  Theme.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 09/07/26.
//


import UIKit

enum Theme {
    static let background = UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 0.05, green: 0.06, blue: 0.09, alpha: 1)
        : UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1)
    }

    static let cardBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1)
        : .white
    }

    static let accent = UIColor(red: 0.36, green: 0.40, blue: 0.98, alpha: 1)
    static let accentSoft = accent.withAlphaComponent(0.12)

    static let success = UIColor(red: 0.20, green: 0.78, blue: 0.55, alpha: 1)
    static let successSoft = success.withAlphaComponent(0.12)

    static let warning = UIColor(red: 0.98, green: 0.65, blue: 0.15, alpha: 1)
    static let danger = UIColor(red: 0.95, green: 0.32, blue: 0.36, alpha: 1)
    static let dangerSoft = danger.withAlphaComponent(0.12)

    static let textPrimary = UIColor.label
    static let textSecondary = UIColor.secondaryLabel

    static let cornerRadiusLarge: CGFloat = 24
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 10
}

extension UIView {
    func addCardShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 6)
    }
}

final class StatusPill: UIView {
    private let dot = UIView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 14
        clipsToBounds = true

        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.layer.cornerRadius = 4

        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [dot, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    enum Style {
        case idle
        case active
        case success
        case warning
        case danger

        var color: UIColor {
            switch self {
            case .idle: return .systemGray
            case .active: return Theme.accent
            case .success: return Theme.success
            case .warning: return Theme.warning
            case .danger: return Theme.danger
            }
        }

        var background: UIColor {
            switch self {
            case .idle: return UIColor.systemGray.withAlphaComponent(0.12)
            case .active: return Theme.accentSoft
            case .success: return Theme.successSoft
            case .warning: return Theme.warning.withAlphaComponent(0.12)
            case .danger: return Theme.dangerSoft
            }
        }
    }

    func configure(text: String, style: Style) {
        label.text = text
        label.textColor = style.color
        dot.backgroundColor = style.color
        backgroundColor = style.background
    }
}
