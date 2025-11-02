//
//  APIService.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import Foundation

@MainActor
class APIService {
    static let shared = APIService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Generic Request Method

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Add headers
        var headers = APIConfig.Headers.defaultHeaders

        // Add auth token if required
        if requiresAuth {
            if let token = AuthService.shared.authToken {
                headers[APIConfig.Headers.authorization] = "Bearer \(token)"
            } else {
                throw APIError.unauthorized
            }
        }

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Encode body if provided
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        // Execute request
        let (data, response) = try await session.data(for: request)

        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                throw APIError.decodingError
            }
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Vacation Methods

    func fetchVacations() async throws -> [Vacation] {
        struct VacationsResponse: Codable {
            let vacations: [Vacation]
        }

        let response: VacationsResponse = try await request(
            endpoint: APIConfig.Endpoints.vacations,
            method: .get,
            requiresAuth: true
        )

        return response.vacations
    }

    func fetchVacation(id: UUID) async throws -> Vacation {
        let vacation: Vacation = try await request(
            endpoint: APIConfig.Endpoints.vacation(id: id.uuidString),
            method: .get,
            requiresAuth: true
        )

        return vacation
    }

    func createVacation(vacation: Vacation) async throws -> Vacation {
        let createdVacation: Vacation = try await request(
            endpoint: APIConfig.Endpoints.createVacation,
            method: .post,
            body: vacation,
            requiresAuth: true
        )

        return createdVacation
    }
    
    func uploadPhotos(photos: [Data]) async throws -> [UploadedPhoto] {
        guard let url = URL(string: APIConfig.Endpoints.uploadPhotosBatch) else {
            throw APIError.invalidResponse
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add auth token
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw APIError.unauthorized
        }
        
        // Create multipart body
        var body = Data()
        
        for (index, photoData) in photos.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"photos\"; filename=\"photo\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(photoData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // Upload
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        // Parse response
        struct UploadResponse: Codable {
            let photos: [UploadedPhoto]
            let count: Int
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let uploadResponse = try decoder.decode(UploadResponse.self, from: data)
        
        return uploadResponse.photos
    }
    
    // MARK: - Friend Methods
    
    func fetchFriends() async throws -> [FriendInfo] {
        struct FriendsResponse: Codable {
            let friends: [FriendData]
            
            struct FriendData: Codable {
                let id: String
                let name: String
                let color: String
                let vacationCount: Int
                let locationCount: Int
                let isVisible: Bool
            }
        }
        
        let response: FriendsResponse = try await request(
            endpoint: APIConfig.Endpoints.friends,
            method: .get,
            requiresAuth: true
        )
        
        return response.friends.map { friend in
            FriendInfo(
                id: UUID(uuidString: friend.id) ?? UUID(),
                name: friend.name,
                color: friend.color,
                vacationCount: friend.vacationCount,
                locationCount: friend.locationCount,
                isVisible: friend.isVisible
            )
        }
    }
    
    func sendFriendRequest(userId: UUID) async throws {
        // TODO: Implement actual API call
    }
    
    func acceptFriendRequest(userId: UUID) async throws {
        // TODO: Implement actual API call
    }
    
    func removeFriend(userId: UUID) async throws {
        // TODO: Implement actual API call
    }
    
    // MARK: - AI Methods
    
    func generateItinerary(title: String, photos: [UploadedPhoto]) async throws -> Vacation {
        struct GenerateRequest: Codable {
            let title: String
            let photos: [PhotoMetadata]
            
            struct PhotoMetadata: Codable {
                let imageURL: String
                let thumbnailURL: String?
                let captureDate: String?
                let coordinates: CoordinateData?
                
                struct CoordinateData: Codable {
                    let latitude: Double
                    let longitude: Double
                }
            }
        }
        
        struct GenerateResponse: Codable {
            let vacation: VacationResponse
            
            struct VacationResponse: Codable {
                let id: String
                let title: String
                let startDate: String?
                let endDate: String?
                let aiGeneratedItinerary: String?
                let locations: [LocationResponse]
            }
            
            struct LocationResponse: Codable {
                let id: String
                let name: String
                let coordinate: CoordinateResponse
                let visitDate: String?
                let activities: [ActivityResponse]
                
                struct CoordinateResponse: Codable {
                    let latitude: Double
                    let longitude: Double
                }
                
                struct ActivityResponse: Codable {
                    let id: String
                    let title: String
                    let description: String
                    let time: String?
                    let aiGenerated: Bool
                }
            }
        }
        
        // Convert UploadedPhoto to request format
        let photoMetadata = photos.map { photo in
            GenerateRequest.PhotoMetadata(
                imageURL: photo.imageURL,
                thumbnailURL: photo.thumbnailURL,
                captureDate: photo.captureDate,
                coordinates: photo.location.map { loc in
                    GenerateRequest.PhotoMetadata.CoordinateData(
                        latitude: loc.latitude,
                        longitude: loc.longitude
                    )
                }
            )
        }
        
        let requestBody = GenerateRequest(title: title, photos: photoMetadata)
        
        let response: GenerateResponse = try await request(
            endpoint: APIConfig.Endpoints.generateItinerary,
            method: .post,
            body: requestBody,
            requiresAuth: true
        )
        
        // Convert response to Vacation model
        let dateFormatter = ISO8601DateFormatter()
        
        let locations = response.vacation.locations.map { loc in
            let activities = loc.activities.map { act in
                Activity(
                    id: UUID(uuidString: act.id) ?? UUID(),
                    title: act.title,
                    description: act.description,
                    time: act.time != nil ? (dateFormatter.date(from: act.time!) ?? Date()) : Date(),
                    aiGenerated: act.aiGenerated
                )
            }
            
            return VacationLocation(
                id: UUID(uuidString: loc.id) ?? UUID(),
                name: loc.name,
                coordinate: Coordinate(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude),
                visitDate: loc.visitDate != nil ? (dateFormatter.date(from: loc.visitDate!) ?? Date()) : Date(),
                photos: [],
                activities: activities
            )
        }
        
        let vacation = Vacation(
            id: UUID(uuidString: response.vacation.id) ?? UUID(),
            title: response.vacation.title,
            startDate: response.vacation.startDate != nil ? (dateFormatter.date(from: response.vacation.startDate!) ?? Date()) : Date(),
            endDate: response.vacation.endDate != nil ? (dateFormatter.date(from: response.vacation.endDate!) ?? Date()) : Date(),
            locations: locations
        )
        
        return vacation
    }
    
    func analyzePhoto(photo: Data) async throws -> PhotoAnalysis {
        // TODO: Implement AI photo analysis
        throw APIError.notImplemented
    }
    
    // MARK: - Article Methods
    
    func fetchArticles(location: String) async throws -> [Article] {
        // TODO: Implement actual API call
        return []
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case notImplemented
    case notFound
    case invalidResponse
    case decodingError
    case networkError
    case unauthorized
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This feature is not yet implemented."
        case .notFound:
            return "Resource not found."
        case .invalidResponse:
            return "Invalid server response."
        case .decodingError:
            return "Failed to decode server response."
        case .networkError:
            return "Network connection error."
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .serverError(let code):
            return "Server error (code: \(code))."
        }
    }
}

// MARK: - Photo Analysis Response
struct PhotoAnalysis: Codable {
    let location: Coordinate?
    let timestamp: Date?
    let detectedActivity: String?
    let confidence: Double
}

// MARK: - Uploaded Photo Response
struct UploadedPhoto: Codable {
    let id: String
    let imageURL: String
    let thumbnailURL: String?
    let captureDate: String?
    let location: PhotoCoordinate?
    let hasExif: Bool
    
    struct PhotoCoordinate: Codable {
        let latitude: Double
        let longitude: Double
    }
}

// MARK: - Friend Info Response
struct FriendInfo: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
    let vacationCount: Int
    let locationCount: Int
    let isVisible: Bool
}

