//
//  FeedDebugCell.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 09/07/26.
//


import UIKit

final class FeedDebugCell: UITableViewCell {
    static let reuseId = "FeedDebugCell"

    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        label.font = .systemFont(ofSize: 12)
        label.textColor = Theme.textSecondary
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(text: String) {
        label.text = text
    }
}
