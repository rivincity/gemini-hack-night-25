//
//  GlobeViewController.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import UIKit
import MapKit
import SwiftUI
import PhotosUI

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
        print("🗺️ Loading vacation pins from backend...")
        
        Task {
            do {
                // Fetch vacations from backend
                let vacations = try await APIService.shared.fetchVacations()
                print("✅ Fetched \(vacations.count) vacations from backend")
                
                await MainActor.run {
                    mapView.removeAnnotations(mapView.annotations)
                    
                    // Create annotations from fetched vacations
                    for vacation in vacations {
                        // Create a user object (owner info should be in vacation)
                        let owner = User(
                            id: UUID(),
                            name: "You", // Default to "You" for now
                            color: "#FF6B6B",
                            vacations: [vacation]
                        )
                        
                        // Create pins for each location in the vacation
                        for location in vacation.locations {
                            let annotation = VacationAnnotation(
                                location: location,
                                vacation: vacation,
                                user: owner
                            )
                            mapView.addAnnotation(annotation)
                            print("📍 Added pin for \(location.name)")
                        }
                    }
                    
                    print("✅ Loaded \(mapView.annotations.count) pins on map")
                }
            } catch {
                print("❌ Error loading vacations: \(error.localizedDescription)")
                // Fallback to empty map if error
                await MainActor.run {
                    mapView.removeAnnotations(mapView.annotations)
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
            self.presentPhotoPicker()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0 // 0 = unlimited, allow batch selection

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func uploadPhotosAndGenerateItinerary(_ images: [UIImage]) {
        // Show loading indicator
        let loadingAlert = UIAlertController(title: "Creating Vacation", message: "Uploading photos and generating itinerary...", preferredStyle: .alert)
        present(loadingAlert, animated: true)

        Task {
            do {
                // Convert images to Data
                let imageDataArray = images.compactMap { $0.jpegData(compressionQuality: 0.8) }

                // Upload photos to backend
                let uploadedPhotos = try await uploadPhotosBatch(imageDataArray)

                if uploadedPhotos.isEmpty {
                    await MainActor.run {
                        loadingAlert.dismiss(animated: true) {
                            self.showErrorAlert("No photos could be uploaded. Please try again.")
                        }
                    }
                    return
                }

                // Generate itinerary with AI
                let vacation = try await generateItineraryFromPhotos(uploadedPhotos)

                // Dismiss loading and show success
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        self.showSuccessAlert(vacation)
                        self.loadPins() // Reload to show new vacation
                    }
                }

            } catch {
                print("❌ FATAL ERROR: Vacation creation failed")
                print("🔍 Error type: \(type(of: error))")
                print("📝 Error description: \(error.localizedDescription)")
                if let apiError = error as? APIError {
                    print("🚨 API Error details: \(apiError)")
                }

                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        let errorMessage: String
                        if let apiError = error as? APIError {
                            switch apiError {
                            case .unauthorized:
                                errorMessage = "You are not logged in. Please log in and try again."
                            case .networkError:
                                errorMessage = "Network connection error. Check your internet connection."
                            case .serverError(let code):
                                errorMessage = "Server error (code \(code)). Please try again later."
                            case .decodingError:
                                errorMessage = "Failed to process server response. Please check backend logs."
                            default:
                                errorMessage = "Failed to create vacation: \(error.localizedDescription)"
                            }
                        } else {
                            errorMessage = "Failed to create vacation: \(error.localizedDescription)"
                        }
                        self.showErrorAlert(errorMessage)
                    }
                }
            }
        }
    }

    private func uploadPhotosBatch(_ imageData: [Data]) async throws -> [PhotoMetadata] {
        guard let url = URL(string: APIConfig.Endpoints.uploadPhotosBatch) else {
            throw APIError.invalidResponse
        }

        print("✅ DEBUG: Starting photo upload (no auth)")
        print("📸 DEBUG: Uploading \(imageData.count) photos")
        print("🔗 DEBUG: Endpoint: \(APIConfig.Endpoints.uploadPhotosBatch)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create multipart/form-data body
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        for (index, data) in imageData.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"photos\"; filename=\"photo\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ ERROR: Invalid response from server")
            throw APIError.invalidResponse
        }

        print("📡 DEBUG: Upload response status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            let errorBody = String(data: responseData, encoding: .utf8) ?? "No error body"
            print("❌ ERROR: Upload failed with status \(httpResponse.statusCode)")
            print("📄 ERROR Response body: \(errorBody)")
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            let uploadResponse = try JSONDecoder().decode(BatchUploadResponse.self, from: responseData)
            print("✅ DEBUG: Successfully uploaded \(uploadResponse.count) photos")
            return uploadResponse.photos
        } catch {
            print("❌ ERROR: Failed to decode upload response: \(error)")
            print("📄 Response body: \(String(data: responseData, encoding: .utf8) ?? "nil")")
            throw APIError.decodingError
        }
    }

    private func generateItineraryFromPhotos(_ photos: [PhotoMetadata]) async throws -> Vacation {
        guard let url = URL(string: APIConfig.Endpoints.generateItinerary) else {
            throw APIError.invalidResponse
        }

        print("🤖 DEBUG: Starting AI itinerary generation (no auth)")
        print("📸 DEBUG: Processing \(photos.count) photos")
        print("🔗 DEBUG: Endpoint: \(APIConfig.Endpoints.generateItinerary)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // 2 minutes for Gemini Vision processing

        // Create request body
        let requestBody: [String: Any] = [
            "photos": photos.map { photo in
                var dict: [String: Any] = [
                    "imageURL": photo.imageURL,
                    "captureDate": photo.captureDate ?? ""
                ]
                if let location = photo.location {
                    dict["coordinates"] = [
                        "latitude": location.latitude,
                        "longitude": location.longitude
                    ]
                }
                return dict
            },
            "title": "My Vacation"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Use custom URLSession with longer timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        let session = URLSession(configuration: config)
        
        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ ERROR: Invalid response from AI endpoint")
            throw APIError.invalidResponse
        }

        print("📡 DEBUG: AI generation response status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 201 && httpResponse.statusCode != 200 {
            let errorBody = String(data: responseData, encoding: .utf8) ?? "No error body"
            print("❌ ERROR: AI generation failed with status \(httpResponse.statusCode)")
            print("📄 ERROR Response body: \(errorBody)")
            throw APIError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let aiResponse = try decoder.decode(AIGenerationResponse.self, from: responseData)
            print("✅ DEBUG: Successfully generated vacation: \(aiResponse.vacation.title)")
            return aiResponse.vacation
        } catch {
            print("❌ ERROR: Failed to decode AI response: \(error)")
            print("📄 Response body: \(String(data: responseData, encoding: .utf8) ?? "nil")")
            throw APIError.decodingError
        }
    }

    private func showSuccessAlert(_ vacation: Vacation) {
        let alert = UIAlertController(
            title: "Vacation Created!",
            message: "Your vacation \"\(vacation.title)\" has been created with AI-generated itinerary.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "View", style: .default) { _ in
            // Navigate to vacation detail
            self.showVacationDetail(vacation)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showVacationDetail(_ vacation: Vacation) {
        // You can implement this to show detail view
        print("Show detail for vacation: \(vacation.title)")
    }

    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
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

// MARK: - PHPickerViewControllerDelegate
extension GlobeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else { return }

        var selectedImages: [UIImage] = []
        let group = DispatchGroup()

        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                defer { group.leave() }
                if let image = object as? UIImage {
                    selectedImages.append(image)
                }
            }
        }

        group.notify(queue: .main) {
            if !selectedImages.isEmpty {
                self.uploadPhotosAndGenerateItinerary(selectedImages)
            }
        }
    }
}

// MARK: - Response Models
struct PhotoMetadata: Codable {
    let id: String
    let imageURL: String
    let thumbnailURL: String?
    let captureDate: String?
    let location: PhotoCoordinate?
    let hasExif: Bool
}

struct PhotoCoordinate: Codable {
    let latitude: Double
    let longitude: Double
}

struct BatchUploadResponse: Codable {
    let photos: [PhotoMetadata]
    let count: Int
    let message: String?
}

struct AIGenerationResponse: Codable {
    let vacation: Vacation
    let message: String?
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

