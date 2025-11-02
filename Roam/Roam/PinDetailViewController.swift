//
//  PinDetailViewController.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import UIKit
import SafariServices
import SwiftUI

class PinDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let location: VacationLocation
    private let vacation: Vacation
    private let user: User
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var headerView: UIView!
    private var locationLabel: UILabel!
    private var dateLabel: UILabel!
    private var itinerarySection: UIView!
    private var photoAlbumButton: UIButton!
    private var flightsButton: UIButton!
    private var articlesSection: UIView!
    
    // MARK: - Initialization
    init(location: VacationLocation, vacation: Vacation, user: User) {
        self.location = location
        self.vacation = vacation
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateContent()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = location.name
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        // Setup ScrollView
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Header View
        headerView = createHeaderView()
        contentView.addSubview(headerView)
        
        // Photo Album Button
        photoAlbumButton = createActionButton(
            title: "View Photo Album",
            icon: "photo.on.rectangle.angled",
            backgroundColor: .systemBlue
        )
        photoAlbumButton.addTarget(self, action: #selector(photoAlbumTapped), for: .touchUpInside)
        contentView.addSubview(photoAlbumButton)
        
        // Flights Button
        flightsButton = createActionButton(
            title: "Book Flights to \(location.name)",
            icon: "airplane.departure",
            backgroundColor: .systemGreen
        )
        flightsButton.addTarget(self, action: #selector(flightsTapped), for: .touchUpInside)
        contentView.addSubview(flightsButton)
        
        // Itinerary Section
        itinerarySection = createItinerarySection()
        contentView.addSubview(itinerarySection)
        
        // Articles Section
        articlesSection = createArticlesSection()
        contentView.addSubview(articlesSection)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            photoAlbumButton.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            photoAlbumButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            photoAlbumButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            photoAlbumButton.heightAnchor.constraint(equalToConstant: 50),
            
            flightsButton.topAnchor.constraint(equalTo: photoAlbumButton.bottomAnchor, constant: 12),
            flightsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            flightsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            flightsButton.heightAnchor.constraint(equalToConstant: 50),
            
            itinerarySection.topAnchor.constraint(equalTo: flightsButton.bottomAnchor, constant: 30),
            itinerarySection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            itinerarySection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            articlesSection.topAnchor.constraint(equalTo: itinerarySection.bottomAnchor, constant: 30),
            articlesSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            articlesSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            articlesSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Create UI Components
    private func createHeaderView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        
        locationLabel = UILabel()
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.font = .systemFont(ofSize: 24, weight: .bold)
        locationLabel.numberOfLines = 0
        view.addSubview(locationLabel)
        
        dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 16, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        view.addSubview(dateLabel)
        
        let ownerLabel = UILabel()
        ownerLabel.translatesAutoresizingMaskIntoConstraints = false
        ownerLabel.font = .systemFont(ofSize: 14, weight: .medium)
        ownerLabel.text = "📍 \(user.name)'s Trip"
        if let color = user.color.hexToUIColor() {
            ownerLabel.textColor = color
        }
        view.addSubview(ownerLabel)
        
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            locationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            dateLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            ownerLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            ownerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ownerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ownerLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
        
        return view
    }
    
    private func createActionButton(title: String, icon: String, backgroundColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 12
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let image = UIImage(systemName: icon, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        
        return button
    }
    
    private func createItinerarySection() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "AI-Generated Itinerary"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        container.addSubview(titleLabel)
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        container.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Add activity cards
        for activity in location.activities {
            let activityCard = createActivityCard(activity: activity)
            stackView.addArrangedSubview(activityCard)
        }
        
        if location.activities.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No activities recorded yet"
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.font = .systemFont(ofSize: 14)
            stackView.addArrangedSubview(emptyLabel)
        }
        
        return container
    }
    
    private func createActivityCard(activity: Activity) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 10
        
        let iconLabel = UILabel()
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.text = activity.aiGenerated ? "🤖" : "📝"
        iconLabel.font = .systemFont(ofSize: 24)
        card.addSubview(iconLabel)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = activity.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 0
        card.addSubview(titleLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = activity.description
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        card.addSubview(descriptionLabel)
        
        let timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: activity.time)
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .tertiaryLabel
        card.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            iconLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            iconLabel.widthAnchor.constraint(equalToConstant: 30),
            
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            
            timeLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            timeLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        
        return card
    }
    
    private func createArticlesSection() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Recommended Articles"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        container.addSubview(titleLabel)
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        container.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Add mock articles
        let mockArticles = [
            Article(title: "Top 10 Things to Do in \(location.name)", url: "https://www.google.com/search?q=things+to+do+\(location.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")", source: "Travel Guide"),
            Article(title: "Best Restaurants in \(location.name)", url: "https://www.google.com/search?q=best+restaurants+\(location.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")", source: "Food & Travel"),
            Article(title: "Hidden Gems of \(location.name)", url: "https://www.google.com/search?q=hidden+gems+\(location.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")", source: "Local Insights")
        ]
        
        for article in mockArticles {
            let articleButton = createArticleButton(article: article)
            stackView.addArrangedSubview(articleButton)
        }
        
        return container
    }
    
    private func createArticleButton(article: Article) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 10
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = article.title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.numberOfLines = 2
        button.addSubview(titleLabel)
        
        let sourceLabel = UILabel()
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.text = article.source
        sourceLabel.font = .systemFont(ofSize: 12)
        sourceLabel.textColor = .secondaryLabel
        button.addSubview(sourceLabel)
        
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.tintColor = .secondaryLabel
        button.addSubview(chevron)
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),
            
            sourceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            sourceLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 12),
            sourceLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),
            sourceLabel.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12),
            
            chevron.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -12),
            chevron.widthAnchor.constraint(equalToConstant: 12)
        ])
        
        button.addTarget(self, action: #selector(articleTapped(_:)), for: .touchUpInside)
        button.tag = mockArticles.firstIndex(where: { $0.id == article.id }) ?? 0
        
        return button
    }
    
    // MARK: - Populate Content
    private func populateContent() {
        locationLabel.text = location.name
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        dateLabel.text = "Visited: \(formatter.string(from: location.visitDate))"
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func photoAlbumTapped() {
        if user.name == "You" {
            let alert = UIAlertController(
                title: "Photo Album",
                message: "Your photo album for \(location.name) would open here",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(
                title: "Private Album",
                message: "\(user.name)'s photos are private",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    @objc private func flightsTapped() {
        // Extract city name for search
        let cityName = location.name.components(separatedBy: ",").first ?? location.name
        let searchQuery = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.google.com/flights?q=flights+to+\(searchQuery)"
        
        if let url = URL(string: urlString) {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated: true)
        }
    }
    
    @objc private func articleTapped(_ sender: UIButton) {
        // In a real app, we'd open the specific article URL
        let cityName = location.name.components(separatedBy: ",").first ?? location.name
        let searchQuery = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.google.com/search?q=travel+guide+\(searchQuery)"
        
        if let url = URL(string: urlString) {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated: true)
        }
    }
}

// Mock articles array for article button tagging
private var mockArticles: [Article] = []

// MARK: - SwiftUI Preview
#Preview {
    let mockLocation = VacationLocation(
        name: "Paris, France",
        coordinate: Coordinate(latitude: 48.8566, longitude: 2.3522),
        visitDate: Date(),
        photos: [
            Photo(imageURL: "eiffel_tower", captureDate: Date())
        ],
        activities: [
            Activity(title: "Eiffel Tower Visit", description: "Visited the iconic Eiffel Tower at sunset", time: Date(), aiGenerated: true),
            Activity(title: "Louvre Museum", description: "Explored the world's largest art museum", time: Date().addingTimeInterval(3600), aiGenerated: true)
        ]
    )
    
    let mockVacation = Vacation(
        title: "European Adventure",
        startDate: Date().addingTimeInterval(-60*60*24*7),
        endDate: Date(),
        locations: [mockLocation]
    )
    
    let mockUser = User(
        name: "You",
        color: "#FF6B6B",
        vacations: [mockVacation]
    )
    
    return PinDetailViewController(location: mockLocation, vacation: mockVacation, user: mockUser)
}

