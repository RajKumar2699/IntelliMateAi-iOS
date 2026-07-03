//
//  AppCoordinator.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//


import UIKit

final class AppCoordinator {
    private let window: UIWindow

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let apiClient = URLSessionAPIClient()
        let service = ChatServiceImpl(apiClient: apiClient)
        let repository = ChatRepositoryImpl(service: service)
        let viewModel = ChatViewModel(repository: repository)
        let chatViewController = ChatViewController(viewModel: viewModel)

        let navigationController = UINavigationController(rootViewController: chatViewController)
        navigationController.navigationBar.prefersLargeTitles = true

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}