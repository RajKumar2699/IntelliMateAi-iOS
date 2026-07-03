//
//  MainTabBarController.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 03/07/26.
//


import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        let apiClient = URLSessionAPIClient()
        let chatService = ChatServiceImpl(apiClient: apiClient)
        let chatRepository = ChatRepositoryImpl(service: chatService)
        let chatViewModel = ChatViewModel(repository: chatRepository)
        let aiChatVC = ChatViewController(viewModel: chatViewModel)
        aiChatVC.title = "AI Chat Assistant"

        let resumeBuilderVC = ResumeBuilderViewController()
        resumeBuilderVC.title = "AI Resume Builder"

        let chatNav = UINavigationController(rootViewController: aiChatVC)
        let resumeNav = UINavigationController(rootViewController: resumeBuilderVC)

        chatNav.tabBarItem = UITabBarItem(
            title: "AI Chat",
            image: UIImage(systemName: "message.fill"),
            selectedImage: UIImage(systemName: "message.fill")
        )

        resumeNav.tabBarItem = UITabBarItem(
            title: "Resume",
            image: UIImage(systemName: "doc.text.fill"),
            selectedImage: UIImage(systemName: "doc.text.fill")
        )

        viewControllers = [chatNav, resumeNav]
    }

    private func setupAppearance() {
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .secondaryLabel
        tabBar.backgroundColor = .systemBackground
    }
}
