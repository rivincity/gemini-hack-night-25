//
//  APIConfig.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import Foundation

struct APIConfig {
    // MARK: - Base URLs
    static let baseURL = "https://api.roamapp.com" // TODO: Replace with actual backend URL
    static let apiVersion = "/v1"
    
    // MARK: - Endpoints
    struct Endpoints {
        // Authentication
        static let login = "\(baseURL)\(apiVersion)/auth/login"
        static let register = "\(baseURL)\(apiVersion)/auth/register"
        static let logout = "\(baseURL)\(apiVersion)/auth/logout"
        static let refreshToken = "\(baseURL)\(apiVersion)/auth/refresh"
        
        // Users
        static let currentUser = "\(baseURL)\(apiVersion)/users/me"
        static let updateProfile = "\(baseURL)\(apiVersion)/users/me"
        static let userVacations = "\(baseURL)\(apiVersion)/users/me/vacations"
        
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
        static let uploadPhotos = "\(baseURL)\(apiVersion)/vacations/photos"
        
        // AI Services
        static let generateItinerary = "\(baseURL)\(apiVersion)/ai/itinerary"
        static let analyzePhotos = "\(baseURL)\(apiVersion)/ai/analyze"
        
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
        static let enablePhotoUpload = false // Coming soon
        static let enableRealTimeFriends = false // Coming soon
        static let enableOfflineMode = false // Coming soon
    }
}

