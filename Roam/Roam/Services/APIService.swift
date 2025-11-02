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

