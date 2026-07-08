//
//  MainTabBarController.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 03/07/26.
//


import UIKit

final class MainTabBarController: UITabBarController {

    private let baseURL = AppConfiguration.baseURL
    private let apiClient = URLSessionAPIClient()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        guard let backendURL = URL(string: baseURL) else {
            assertionFailure("Invalid base URL: \(baseURL)")
            return
        }

        let chatService = ChatServiceImpl(apiClient: apiClient)
        let chatRepository = ChatRepositoryImpl(service: chatService)
        let chatViewModel = ChatViewModel(repository: chatRepository)
        let aiChatVC = ChatViewController(viewModel: chatViewModel)
        aiChatVC.title = "AI Chat Assistant"

        let resumeRepository = ResumeRepositoryImpl(baseURL: baseURL)
        let resumeViewModel = ResumeBuilderViewModel(repository: resumeRepository)
        let resumeVC = ResumeUploadViewController(viewModel: resumeViewModel)
        resumeVC.title = "Resume Analyzer"

        let backendAPI = BackendAPIService(baseURL: backendURL)
        let realtimeManager = OpenAIRealtimeManager(backendAPI: backendAPI)
        let preferredLanguageHint = Self.preferredLanguageCode()

        let voiceViewModel = AdvancedVoiceViewModel(
            realtimeManager: realtimeManager,
            preferredLanguageHint: preferredLanguageHint
        )
        let voiceVC = AdvancedVoiceViewController(viewModel: voiceViewModel)
        voiceVC.title = "Voice Assistant"

        let interviewVC = InterviewViewController()
        interviewVC.title = "Interview Assistant"

        let chatNav = makeNavigationController(
            rootViewController: aiChatVC,
            title: "AI Chat",
            imageName: "message.fill"
        )

        let resumeNav = makeNavigationController(
            rootViewController: resumeVC,
            title: "Resume",
            imageName: "doc.text.magnifyingglass"
        )

        let voiceNav = makeNavigationController(
            rootViewController: voiceVC,
            title: "Voice",
            imageName: "waveform.circle.fill"
        )

        let interviewNav = makeNavigationController(
            rootViewController: interviewVC,
            title: "Interview",
            imageName: "person.2.wave.2.fill"
        )

        setViewControllers([chatNav, resumeNav, voiceNav, interviewNav], animated: false)
    }

    private func makeNavigationController(
        rootViewController: UIViewController,
        title: String,
        imageName: String
    ) -> UINavigationController {
        let nav = UINavigationController(rootViewController: rootViewController)
        nav.navigationBar.prefersLargeTitles = true
        rootViewController.navigationItem.largeTitleDisplayMode = .always
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: imageName),
            selectedImage: UIImage(systemName: imageName)
        )
        return nav
    }

    private func setupAppearance() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .systemBackground

        tabBar.standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = tabAppearance
        }

        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .secondaryLabel
    }

    private static func preferredLanguageCode() -> String? {
        guard let preferred = Locale.preferredLanguages.first else {
            return nil
        }

        let locale = Locale(identifier: preferred)
        if #available(iOS 16.0, *) {
            return locale.language.languageCode?.identifier
        } else {
            return locale.languageCode
        }
    }
}
