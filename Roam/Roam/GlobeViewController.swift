//
//  GlobeViewController.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import UIKit
import MapKit
import SwiftUI

class GlobeViewController: UIViewController {
    
    // MARK: - Properties
    private var mapView: MKMapView!
    private var friendsButton: UIButton!
    private var addVacationButton: UIButton!
    private var users: [User] = User.mockUsers
    private var selectedUser: User?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMapView()
        loadPins()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Roam"
        
        // Setup MapView
        mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.mapType = .standard
        mapView.showsUserLocation = false
        view.addSubview(mapView)
        
        // Setup Friends Button
        friendsButton = UIButton(type: .system)
        friendsButton.translatesAutoresizingMaskIntoConstraints = false
        friendsButton.setImage(UIImage(systemName: "person.2.fill"), for: .normal)
        friendsButton.backgroundColor = .systemBackground
        friendsButton.tintColor = .systemBlue
        friendsButton.layer.cornerRadius = 25
        friendsButton.layer.shadowColor = UIColor.black.cgColor
        friendsButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        friendsButton.layer.shadowRadius = 4
        friendsButton.layer.shadowOpacity = 0.2
        friendsButton.addTarget(self, action: #selector(friendsButtonTapped), for: .touchUpInside)
        view.addSubview(friendsButton)
        
        // Setup Add Vacation Button
        addVacationButton = UIButton(type: .system)
        addVacationButton.translatesAutoresizingMaskIntoConstraints = false
        addVacationButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addVacationButton.backgroundColor = .systemBlue
        addVacationButton.tintColor = .white
        addVacationButton.layer.cornerRadius = 30
        addVacationButton.layer.shadowColor = UIColor.black.cgColor
        addVacationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addVacationButton.layer.shadowRadius = 4
        addVacationButton.layer.shadowOpacity = 0.3
        addVacationButton.addTarget(self, action: #selector(addVacationButtonTapped), for: .touchUpInside)
        view.addSubview(addVacationButton)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            friendsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            friendsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            friendsButton.widthAnchor.constraint(equalToConstant: 50),
            friendsButton.heightAnchor.constraint(equalToConstant: 50),
            
            addVacationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addVacationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addVacationButton.widthAnchor.constraint(equalToConstant: 60),
            addVacationButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupMapView() {
        // Set initial region to show world view
        let worldRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
        )
        mapView.setRegion(worldRegion, animated: false)
    }
    
    // MARK: - Load Pins
    private func loadPins() {
        mapView.removeAnnotations(mapView.annotations)
        
        for user in users {
            for vacation in user.vacations {
                for location in vacation.locations {
                    let annotation = VacationAnnotation(
                        location: location,
                        vacation: vacation,
                        user: user
                    )
                    mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func friendsButtonTapped() {
        let friendsVC = FriendsViewController(users: users)
        friendsVC.delegate = self
        let navController = UINavigationController(rootViewController: friendsVC)
        present(navController, animated: true)
    }
    
    @objc private func addVacationButtonTapped() {
        let alert = UIAlertController(
            title: "Add Vacation",
            message: "Upload photos to create a new vacation itinerary",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Choose Photos", style: .default) { _ in
            // TODO: Implement photo picker
            self.showComingSoonAlert()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showComingSoonAlert() {
        let alert = UIAlertController(
            title: "Coming Soon",
            message: "Photo upload and AI itinerary generation will be available soon!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - MKMapViewDelegate
extension GlobeViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let vacationAnnotation = annotation as? VacationAnnotation else {
            return nil
        }
        
        let identifier = "VacationPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = false
        } else {
            annotationView?.annotation = annotation
        }
        
        // Set pin color based on user
        if let hexColor = vacationAnnotation.user.color.hexToUIColor() {
            annotationView?.markerTintColor = hexColor
        }
        
        annotationView?.glyphImage = UIImage(systemName: "airplane.circle.fill")
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? VacationAnnotation else {
            return
        }
        
        // Show detail view
        let detailVC = PinDetailViewController(
            location: annotation.location,
            vacation: annotation.vacation,
            user: annotation.user
        )
        let navController = UINavigationController(rootViewController: detailVC)
        present(navController, animated: true)
        
        // Deselect annotation
        mapView.deselectAnnotation(annotation, animated: true)
    }
}

// MARK: - FriendsViewControllerDelegate
extension GlobeViewController: FriendsViewControllerDelegate {
    func didUpdateFriendVisibility() {
        loadPins()
    }
}

// MARK: - Custom Annotation
class VacationAnnotation: NSObject, MKAnnotation {
    let location: VacationLocation
    let vacation: Vacation
    let user: User
    
    var coordinate: CLLocationCoordinate2D {
        location.coordinate.clCoordinate
    }
    
    var title: String? {
        location.name
    }
    
    var subtitle: String? {
        vacation.title
    }
    
    init(location: VacationLocation, vacation: Vacation, user: User) {
        self.location = location
        self.vacation = vacation
        self.user = user
    }
}

// MARK: - String Extension for Hex Colors
extension String {
    func hexToUIColor() -> UIColor? {
        var hexSanitized = self.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

// MARK: - SwiftUI Preview
#Preview {
    GlobeViewController()
}

