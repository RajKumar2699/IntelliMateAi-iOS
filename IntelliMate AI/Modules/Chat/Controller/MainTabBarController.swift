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

        let resumeRepository = ResumeRepositoryImpl(baseURL: "http://127.0.0.1:8000")
        let resumeViewModel = ResumeBuilderViewModel(repository: resumeRepository)
        let resumeVC = ResumeUploadViewController(viewModel: resumeViewModel)
        resumeVC.title = "Resume Analyzer"

        let chatNav = UINavigationController(rootViewController: aiChatVC)
        let resumeNav = UINavigationController(rootViewController: resumeVC)

        chatNav.tabBarItem = UITabBarItem(
            title: "AI Chat",
            image: UIImage(systemName: "message.fill"),
            selectedImage: UIImage(systemName: "message.fill")
        )

        resumeNav.tabBarItem = UITabBarItem(
            title: "Resume",
            image: UIImage(systemName: "doc.text.magnifyingglass"),
            selectedImage: UIImage(systemName: "doc.text.magnifyingglass")
        )

        viewControllers = [chatNav, resumeNav]
    }

    private func setupAppearance() {
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .secondaryLabel
        tabBar.backgroundColor = .systemBackground
    }
}
