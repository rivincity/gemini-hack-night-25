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
    
    func fetchAllVacationsWithFriends() async throws -> [(vacation: Vacation, user: User)] {
        // Fetch user's own vacations
        let userVacations = try await fetchVacations()
        
        // Fetch friends
        let friends = try await fetchFriends()
        
        // Create result array with user and friends' vacations
        var result: [(vacation: Vacation, user: User)] = []
        
        // Add user's vacations (if we have current user)
        if let currentUser = AuthService.shared.currentUser {
            result += userVacations.map { ($0, currentUser) }
        }
        
        // Add visible friends' vacations
        for friend in friends where friend.isVisible {
            // Fetch friend's vacations
            let endpoint = "\(APIConfig.baseURL)\(APIConfig.apiVersion)/friends/\(friend.userId.uuidString)/vacations"
            
            struct FriendVacationsResponse: Codable {
                let vacations: [Vacation]
            }
            
            do {
                let response: FriendVacationsResponse = try await request(
                    endpoint: endpoint,
                    method: .get,
                    requiresAuth: false  // No auth required for testing
                )
                
                // Convert Friend to User for display purposes
                let friendUser = User(
                    id: friend.userId,
                    name: friend.name,
                    color: friend.color,
                    vacations: response.vacations,
                    email: friend.email
                )
                
                result += response.vacations.map { ($0, friendUser) }
            } catch {
                print("Failed to fetch vacations for friend \(friend.name): \(error)")
                // Continue with other friends even if one fails
            }
        }
        
        return result
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
    
<<<<<<< HEAD
    func fetchFriends() async throws -> [Friend] {
        struct FriendsResponse: Codable {
            let friends: [FriendDTO]
        }
        
        struct FriendDTO: Codable {
            let id: String
            let name: String
            let email: String?
            let color: String
            let profileImage: String?
            let vacationCount: Int
            let locationCount: Int
            let isVisible: Bool
=======
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
>>>>>>> 4d85dd9f7b7ed3c273246054253abe6859cc4fcf
        }
        
        let response: FriendsResponse = try await request(
            endpoint: APIConfig.Endpoints.friends,
            method: .get,
<<<<<<< HEAD
            requiresAuth: false  // No auth required for testing
        )
        
        return response.friends.compactMap { dto in
            guard let userId = UUID(uuidString: dto.id),
                  let friendId = UUID(uuidString: dto.id) else {
                return nil
            }
            return Friend(
                id: friendId,
                userId: userId,
                name: dto.name,
                email: dto.email,
                color: dto.color,
                profileImage: dto.profileImage,
                vacationCount: dto.vacationCount,
                locationCount: dto.locationCount,
                isVisible: dto.isVisible
=======
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
>>>>>>> 4d85dd9f7b7ed3c273246054253abe6859cc4fcf
            )
        }
    }
    
    func sendFriendRequest(email: String) async throws {
        struct AddFriendRequest: Codable {
            let email: String
        }
        
        struct AddFriendResponse: Codable {
            let message: String
        }
        
        let _: AddFriendResponse = try await request(
            endpoint: APIConfig.Endpoints.addFriend,
            method: .post,
            body: AddFriendRequest(email: email),
            requiresAuth: false  // No auth required for testing
        )
    }
    
    func acceptFriendRequest(friendshipId: UUID) async throws {
        struct AcceptResponse: Codable {
            let message: String
        }
        
        let endpoint = "\(APIConfig.baseURL)\(APIConfig.apiVersion)/friends/accept/\(friendshipId.uuidString)"
        
        let _: AcceptResponse = try await request(
            endpoint: endpoint,
            method: .post,
            requiresAuth: false  // No auth required for testing
        )
    }
    
    func removeFriend(friendId: UUID) async throws {
        struct RemoveFriendResponse: Codable {
            let message: String
        }
        
        let endpoint = "\(APIConfig.baseURL)\(APIConfig.apiVersion)/friends/\(friendId.uuidString)"
        
        let _: RemoveFriendResponse = try await request(
            endpoint: endpoint,
            method: .delete,
            requiresAuth: false  // No auth required for testing
        )
    }
    
    func toggleFriendVisibility(friendId: UUID, isVisible: Bool) async throws {
        struct ToggleVisibilityRequest: Codable {
            let isVisible: Bool
        }
        
        struct ToggleVisibilityResponse: Codable {
            let message: String
        }
        
        let endpoint = "\(APIConfig.baseURL)\(APIConfig.apiVersion)/friends/\(friendId.uuidString)/toggle-visibility"
        
        let _: ToggleVisibilityResponse = try await request(
            endpoint: endpoint,
            method: .post,
            body: ToggleVisibilityRequest(isVisible: isVisible),
            requiresAuth: false  // No auth required for testing
        )
    }
    
    func checkUserExists(email: String) async throws -> User? {
        struct UserSearchRequest: Codable {
            let email: String
        }
        
        struct UserSearchResponse: Codable {
            let exists: Bool
            let user: UserDTO?
        }
        
        struct UserDTO: Codable {
            let id: String
            let name: String
            let email: String
            let color: String
            let profileImage: String?
        }
        
        // For now, this will try to add and catch the error if user doesn't exist
        // In production, you'd have a dedicated search endpoint
        return nil
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

