//
//  ProfileView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showLogoutAlert = false
    @State private var vacations: [Vacation] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Header
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(authService.currentUser?.name.prefix(1) ?? "?")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            Text(authService.currentUser?.name ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(vacations.count) vacation\(vacations.count != 1 ? "s" : "")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                
                // My Vacations
                Section("My Vacations") {
                    if isLoading {
                        ProgressView()
                    } else if !vacations.isEmpty {
                        ForEach(vacations) { vacation in
                            let currentUser = authService.currentUser ?? User(
                                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                                name: "Demo User",
                                color: "#FF6B6B",
                                vacations: [],
                                email: "demo@roam.app"
                            )
                            NavigationLink(destination: VacationDetailView(vacation: vacation, user: currentUser)) {
                                VacationRowView(vacation: vacation)
                            }
                        }
                    } else {
                        Button(action: {}) {
                            Label("Add Your First Vacation", systemImage: "plus.circle")
                        }
                    }
                }
                
                // Settings
                Section("Settings") {
                    NavigationLink(destination: SettingsView()) {
                        Label("Account Settings", systemImage: "gear")
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy", systemImage: "lock.shield")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                }
                
                // About
                Section("About") {
                    NavigationLink(destination: AboutView()) {
                        Label("About Roam", systemImage: "info.circle")
                    }
                    
                    NavigationLink(destination: HelpView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                }
                
                // Logout
                Section {
                    Button(role: .destructive, action: { showLogoutAlert = true }) {
                        HStack {
                            Spacer()
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                loadVacations()
            }
            .refreshable {
                await refreshVacations()
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    Task {
                        try? await authService.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    private func loadVacations() {
        isLoading = true
        Task {
            do {
                vacations = try await APIService.shared.fetchVacations()
                print("✅ Loaded \(vacations.count) vacations for profile")
            } catch {
                print("❌ Failed to load vacations: \(error)")
                vacations = []
            }
            isLoading = false
        }
    }
    
    private func refreshVacations() async {
        do {
            vacations = try await APIService.shared.fetchVacations()
            print("🔄 Refreshed \(vacations.count) vacations for profile")
        } catch {
            print("❌ Failed to refresh vacations: \(error)")
        }
    }
}

#Preview {
    ProfileView()
}

