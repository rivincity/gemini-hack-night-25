//
//  AuthService.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import Foundation
import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var authToken: String?
    
    private init() {
        // Check for stored auth token
        checkAuthStatus()
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) async throws {
        // TODO: Implement actual API call
        // For now, mock authentication
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        // Mock successful login
        self.authToken = "mock_token_\(UUID().uuidString)"
        self.currentUser = User.mockUsers.first
        self.isAuthenticated = true
        
        // Save auth state
        saveAuthState()
    }
    
    func register(name: String, email: String, password: String) async throws {
        // TODO: Implement actual API call
        // For now, mock registration
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock successful registration
        let newUser = User(
            name: name,
            color: "#FF6B6B",
            vacations: []
        )
        
        self.authToken = "mock_token_\(UUID().uuidString)"
        self.currentUser = newUser
        self.isAuthenticated = true
        
        saveAuthState()
    }
    
    func logout() {
        // TODO: Implement actual API call to invalidate token
        
        self.authToken = nil
        self.currentUser = nil
        self.isAuthenticated = false
        
        clearAuthState()
    }
    
    func refreshToken() async throws {
        // TODO: Implement token refresh logic
        guard let _ = authToken else {
            throw AuthError.notAuthenticated
        }
        
        // Mock token refresh
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    // MARK: - Auth State Management
    
    private func checkAuthStatus() {
        // TODO: Check UserDefaults or Keychain for stored auth
        // For now, start unauthenticated
        self.isAuthenticated = false
    }
    
    private func saveAuthState() {
        // TODO: Save to Keychain for security
        UserDefaults.standard.set(authToken, forKey: "authToken")
        UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated")
    }
    
    private func clearAuthState() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case networkError
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not authenticated. Please log in."
        case .invalidCredentials:
            return "Invalid email or password."
        case .networkError:
            return "Network connection error. Please try again."
        case .serverError:
            return "Server error. Please try again later."
        }
    }
}

