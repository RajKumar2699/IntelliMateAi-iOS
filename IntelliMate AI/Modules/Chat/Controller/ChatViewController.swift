import UIKit

final class ChatViewController: UIViewController {
    private let viewModel: ChatViewModel

    private let headerView = ChatHeaderView()
    private let animatedBackgroundView = AnimatedBackgroundView()

    private var headerHeightConstraint: NSLayoutConstraint!
    private var tableTopToHeaderConstraint: NSLayoutConstraint!
    private var tableTopToSafeAreaConstraint: NSLayoutConstraint!

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let inputViewContainer = ChatInputView()
    private let loadingView = LoadingView()
    private let typingIndicatorView = TypingIndicatorView()

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        setupTableView()
        setupLayout()
        bindViewModel()
        updateHeaderVisibility(animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if viewModel.numberOfRows() == 0 {
            headerView.animateAppearance()
        }
    }

    private func configureAppearance() {
        title = "IntelliMate AI"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatTableViewCell.self)
    }

    private func setupLayout() {
        animatedBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(animatedBackgroundView)
        view.addSubview(headerView)
        view.addSubview(tableView)
        view.addSubview(typingIndicatorView)
        view.addSubview(inputViewContainer)
        view.addSubview(loadingView)

        headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: 110)

        tableTopToHeaderConstraint = tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8)
        tableTopToSafeAreaConstraint = tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        tableTopToSafeAreaConstraint.isActive = false

        NSLayoutConstraint.activate([
            animatedBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            animatedBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animatedBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animatedBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerHeightConstraint,

            tableTopToHeaderConstraint,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: typingIndicatorView.topAnchor),

            typingIndicatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            typingIndicatorView.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
            typingIndicatorView.bottomAnchor.constraint(equalTo: inputViewContainer.topAnchor, constant: -8),

            inputViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputViewContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 60),
            loadingView.heightAnchor.constraint(equalToConstant: 60)
        ])

        inputViewContainer.onSendTapped = { [weak self] text in
            guard let self = self else { return }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            self.inputViewContainer.clearText()
            self.viewModel.sendMessage(trimmed)
            self.scrollToBottom(animated: true)
        }
    }

    private func bindViewModel() {
        viewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self = self else { return }

            DispatchQueue.main.async {
                isLoading ? self.loadingView.start() : self.loadingView.stop()
                self.typingIndicatorView.setVisible(isLoading)
            }
        }

        viewModel.onMessagesChanged = { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.updateHeaderVisibility(animated: true)
                self.tableView.reloadData()
                self.scrollToBottom(animated: true)
            }
        }

        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.typingIndicatorView.setVisible(false)
                self?.loadingView.stop()
                self?.presentError(message)
            }
        }
    }

    private func scrollToBottom(animated: Bool) {
        let count = viewModel.numberOfRows()
        guard count > 0 else { return }

        let indexPath = IndexPath(row: count - 1, section: 0)

        DispatchQueue.main.async {
            guard self.tableView.numberOfRows(inSection: 0) > indexPath.row else { return }
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }

    private func presentError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateHeaderVisibility(animated: Bool) {
        let shouldHideHeader = viewModel.numberOfRows() > 0

        headerHeightConstraint.constant = shouldHideHeader ? 0 : 110
        tableTopToHeaderConstraint.isActive = !shouldHideHeader
        tableTopToSafeAreaConstraint.isActive = shouldHideHeader

        if !shouldHideHeader {
            headerView.isHidden = false
        }

        let animations = {
            self.headerView.alpha = shouldHideHeader ? 0 : 1
            self.view.layoutIfNeeded()
        }

        let completion: (Bool) -> Void = { _ in
            self.headerView.isHidden = shouldHideHeader
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChatTableViewCell = tableView.dequeue(ChatTableViewCell.self, for: indexPath)
        cell.configure(with: viewModel.message(at: indexPath.row))
        return cell
    }
}
