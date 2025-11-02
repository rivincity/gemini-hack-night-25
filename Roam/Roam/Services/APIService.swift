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
        // TODO: Implement actual API calls
        // For now, return mock data
        throw APIError.notImplemented
    }
    
    // MARK: - Vacation Methods
    
    func fetchVacations() async throws -> [Vacation] {
        // TODO: Implement actual API call
        // For now, return mock data
        return User.mockUsers.flatMap { $0.vacations }
    }
    
    func fetchVacation(id: UUID) async throws -> Vacation {
        // TODO: Implement actual API call
        guard let vacation = User.mockUsers
            .flatMap({ $0.vacations })
            .first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return vacation
    }
    
    func createVacation(vacation: Vacation) async throws -> Vacation {
        // TODO: Implement actual API call
        return vacation
    }
    
    func uploadPhotos(vacationId: UUID, photos: [Data]) async throws -> [Photo] {
        // TODO: Implement photo upload with progress
        return []
    }
    
    // MARK: - Friend Methods
    
    func fetchFriends() async throws -> [User] {
        // TODO: Implement actual API call
        return User.mockUsers
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
    
    func generateItinerary(photos: [Photo]) async throws -> [Activity] {
        // TODO: Implement Gemini AI integration
        return []
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

