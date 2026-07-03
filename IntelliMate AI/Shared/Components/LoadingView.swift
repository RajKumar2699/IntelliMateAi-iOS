//
//  LoadingView.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import UIKit

final class LoadingView: UIView {
    private let indicator = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        indicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicator)

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func start() {
        isHidden = false
        indicator.startAnimating()
    }

    func stop() {
        indicator.stopAnimating()
        isHidden = true
    }
}