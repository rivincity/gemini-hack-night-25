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
        struct LoginRequest: Codable {
            let email: String
            let password: String
        }

        struct LoginResponse: Codable {
            let user: UserProfile
            let session: Session
        }

        struct UserProfile: Codable {
            let id: String
            let email: String
            let name: String
            let color: String
            let profileImage: String?
        }

        struct Session: Codable {
            let access_token: String
            let refresh_token: String
        }

        guard let url = URL(string: APIConfig.Endpoints.login) else {
            throw AuthError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginRequest = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(loginRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw AuthError.invalidCredentials
        }

        if httpResponse.statusCode != 200 {
            throw AuthError.serverError
        }

        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)

        // Create User object from response
        let user = User(
            id: UUID(uuidString: loginResponse.user.id) ?? UUID(),
            name: loginResponse.user.name,
            profileImage: loginResponse.user.profileImage,
            color: loginResponse.user.color,
            vacations: []
        )

        self.authToken = loginResponse.session.access_token
        self.currentUser = user
        self.isAuthenticated = true

        saveAuthState()
    }

    func register(name: String, email: String, password: String) async throws {
        struct SignupRequest: Codable {
            let email: String
            let password: String
            let name: String
        }

        struct SignupResponse: Codable {
            let user: UserProfile
            let session: Session
        }

        struct UserProfile: Codable {
            let id: String
            let email: String
            let name: String
            let color: String
        }

        struct Session: Codable {
            let access_token: String
            let refresh_token: String
        }

        guard let url = URL(string: APIConfig.Endpoints.signup) else {
            throw AuthError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let signupRequest = SignupRequest(email: email, password: password, name: name)
        request.httpBody = try JSONEncoder().encode(signupRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        if httpResponse.statusCode != 201 && httpResponse.statusCode != 200 {
            throw AuthError.serverError
        }

        let signupResponse = try JSONDecoder().decode(SignupResponse.self, from: data)

        // Create User object from response
        let user = User(
            id: UUID(uuidString: signupResponse.user.id) ?? UUID(),
            name: signupResponse.user.name,
            profileImage: nil,
            color: signupResponse.user.color,
            vacations: []
        )

        self.authToken = signupResponse.session.access_token
        self.currentUser = user
        self.isAuthenticated = true

        saveAuthState()
    }

    func logout() async throws {
        // Call backend logout endpoint
        if let token = authToken {
            guard let url = URL(string: APIConfig.Endpoints.logout) else {
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            // Ignore response, just clear local state
            _ = try? await URLSession.shared.data(for: request)
        }

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
        // Check UserDefaults for stored token
        if let token = UserDefaults.standard.string(forKey: "authToken"),
           UserDefaults.standard.bool(forKey: "isAuthenticated") {
            self.authToken = token
            self.isAuthenticated = true
            // Note: currentUser will be nil until fetched from backend
        } else {
            self.isAuthenticated = false
        }
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

