//
//  ResumeBuilderViewController.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 03/07/26.
//


import UIKit

final class ResumeBuilderViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "AI Resume Builder"

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "AI Resume Builder"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}