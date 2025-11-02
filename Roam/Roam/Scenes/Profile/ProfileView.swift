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
                            
                            Text("\(authService.currentUser?.vacations.count ?? 0) vacation\(authService.currentUser?.vacations.count != 1 ? "s" : "")")
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
                    if let vacations = authService.currentUser?.vacations, !vacations.isEmpty {
                        ForEach(vacations) { vacation in
                            NavigationLink(destination: VacationDetailView(vacation: vacation, user: authService.currentUser!)) {
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
}

#Preview {
    ProfileView()
}

