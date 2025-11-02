//
//  FriendsViewController.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import UIKit

protocol FriendsViewControllerDelegate: AnyObject {
    func didUpdateFriendVisibility()
}

class FriendsViewController: UIViewController {
    
    // MARK: - Properties
    private var users: [User]
    private var tableView: UITableView!
    private var addFriendButton: UIBarButtonItem!
    weak var delegate: FriendsViewControllerDelegate?
    
    // Track which users are visible on the map
    private var visibleUsers: Set<UUID> = []
    
    // MARK: - Initialization
    init(users: [User]) {
        self.users = users
        // All users visible by default
        self.visibleUsers = Set(users.map { $0.id })
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Friends"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        addFriendButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addFriendTapped)
        )
        navigationItem.rightBarButtonItem = addFriendButton
        
        // Setup TableView
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FriendCell.self, forCellReuseIdentifier: FriendCell.identifier)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func addFriendTapped() {
        let alert = UIAlertController(
            title: "Add Friend",
            message: "Enter your friend's username or email",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Username or email"
            textField.autocapitalizationType = .none
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            self?.showComingSoonAlert()
        })
        
        present(alert, animated: true)
    }
    
    private func showComingSoonAlert() {
        let alert = UIAlertController(
            title: "Coming Soon",
            message: "Friend management features will be available soon!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FriendsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FriendCell.identifier, for: indexPath) as? FriendCell else {
            return UITableViewCell()
        }
        
        let user = users[indexPath.row]
        let isVisible = visibleUsers.contains(user.id)
        cell.configure(with: user, isVisible: isVisible)
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Your Friends"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Toggle visibility to show or hide friends' vacation pins on the map"
    }
}

// MARK: - UITableViewDelegate
extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let user = users[indexPath.row]
        let profileVC = UserProfileViewController(user: user)
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK: - FriendCellDelegate
extension FriendsViewController: FriendCellDelegate {
    func didToggleVisibility(for user: User, isVisible: Bool) {
        if isVisible {
            visibleUsers.insert(user.id)
        } else {
            visibleUsers.remove(user.id)
        }
        delegate?.didUpdateFriendVisibility()
    }
}

// MARK: - FriendCell
protocol FriendCellDelegate: AnyObject {
    func didToggleVisibility(for user: User, isVisible: Bool)
}

class FriendCell: UITableViewCell {
    static let identifier = "FriendCell"
    
    weak var delegate: FriendCellDelegate?
    private var user: User?
    
    private let colorIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemGray4.cgColor
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let vacationCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let visibilitySwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(colorIndicator)
        contentView.addSubview(nameLabel)
        contentView.addSubview(vacationCountLabel)
        contentView.addSubview(visibilitySwitch)
        
        visibilitySwitch.addTarget(self, action: #selector(visibilitySwitchChanged), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            colorIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            colorIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorIndicator.widthAnchor.constraint(equalToConstant: 40),
            colorIndicator.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: visibilitySwitch.leadingAnchor, constant: -12),
            
            vacationCountLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            vacationCountLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            vacationCountLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            visibilitySwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            visibilitySwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with user: User, isVisible: Bool) {
        self.user = user
        nameLabel.text = user.name
        
        let vacationCount = user.vacations.count
        let locationCount = user.vacations.flatMap { $0.locations }.count
        vacationCountLabel.text = "\(vacationCount) trip\(vacationCount != 1 ? "s" : ""), \(locationCount) location\(locationCount != 1 ? "s" : "")"
        
        if let color = user.color.hexToUIColor() {
            colorIndicator.backgroundColor = color
        }
        
        visibilitySwitch.isOn = isVisible
        
        // Add icon to color indicator
        let iconLabel = UILabel()
        iconLabel.text = user.name == "You" ? "👤" : "👥"
        iconLabel.font = .systemFont(ofSize: 20)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove old icon if exists
        colorIndicator.subviews.forEach { $0.removeFromSuperview() }
        colorIndicator.addSubview(iconLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: colorIndicator.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: colorIndicator.centerYAnchor)
        ])
    }
    
    @objc private func visibilitySwitchChanged() {
        guard let user = user else { return }
        delegate?.didToggleVisibility(for: user, isVisible: visibilitySwitch.isOn)
    }
}

// MARK: - UserProfileViewController
class UserProfileViewController: UIViewController {
    
    private let user: User
    private var tableView: UITableView!
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "\(user.name)'s Profile"
        
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "VacationCell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension UserProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return user.vacations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VacationCell", for: indexPath)
        let vacation = user.vacations[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = vacation.title
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        config.secondaryText = "\(formatter.string(from: vacation.startDate)) - \(formatter.string(from: vacation.endDate))"
        config.image = UIImage(systemName: "airplane.circle.fill")
        
        if let color = user.color.hexToUIColor() {
            config.imageProperties.tintColor = color
        }
        
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Vacations"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vacation = user.vacations[indexPath.row]
        if let firstLocation = vacation.locations.first {
            let detailVC = PinDetailViewController(
                location: firstLocation,
                vacation: vacation,
                user: user
            )
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

