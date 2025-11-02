//
//  APIConfig.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import Foundation

struct APIConfig {
    // MARK: - Base URLs
    static let baseURL = "https://850a286ace35.ngrok-free.app" // ngrok tunnel to Flask backend
    static let apiVersion = "/api"
    
    // MARK: - Endpoints
    struct Endpoints {
        // Authentication
        static let login = "\(baseURL)\(apiVersion)/auth/login"
        static let signup = "\(baseURL)\(apiVersion)/auth/signup"
        static let logout = "\(baseURL)\(apiVersion)/auth/logout"
        static let currentUser = "\(baseURL)\(apiVersion)/auth/me"
        
        // Friends
        static let friends = "\(baseURL)\(apiVersion)/friends"
        static let friendRequests = "\(baseURL)\(apiVersion)/friends/requests"
        static let addFriend = "\(baseURL)\(apiVersion)/friends/add"
        static let removeFriend = "\(baseURL)\(apiVersion)/friends/remove"
        
        // Vacations
        static let vacations = "\(baseURL)\(apiVersion)/vacations"
        static func vacation(id: String) -> String {
            "\(baseURL)\(apiVersion)/vacations/\(id)"
        }
        static let createVacation = "\(baseURL)\(apiVersion)/vacations"

        // Photos
        static let uploadPhotos = "\(baseURL)\(apiVersion)/photos/upload"
        static let uploadPhotosBatch = "\(baseURL)\(apiVersion)/photos/upload/batch"

        // AI Services
        static let generateItinerary = "\(baseURL)\(apiVersion)/ai/generate-itinerary"
        static let analyzePhoto = "\(baseURL)\(apiVersion)/ai/analyze-photo"
        
        // Articles
        static func articles(location: String) -> String {
            "\(baseURL)\(apiVersion)/articles?location=\(location)"
        }
    }
    
    // MARK: - Headers
    struct Headers {
        static let contentType = "Content-Type"
        static let authorization = "Authorization"
        static let accept = "Accept"
        
        static var defaultHeaders: [String: String] {
            [
                contentType: "application/json",
                accept: "application/json"
            ]
        }
        
        static func authHeaders(token: String) -> [String: String] {
            var headers = defaultHeaders
            headers[authorization] = "Bearer \(token)"
            return headers
        }
    }
    
    // MARK: - Configuration
    static let requestTimeout: TimeInterval = 30
    static let maxRetries = 3
    
    // MARK: - Feature Flags
    struct Features {
        static let enableAIGeneration = true
        static let enablePhotoUpload = true // Backend ready!
        static let enableRealTimeFriends = false // Coming soon
        static let enableOfflineMode = false // Coming soon
    }
}

