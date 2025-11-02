//
//  SettingsView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var name = "John Doe"
    @State private var email = "john@example.com"
    
    var body: some View {
        Form {
            Section("Account Information") {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }
            
            Section {
                Button("Save Changes") {
                    // TODO: Implement save
                }
            }
        }
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    @State private var shareLocation = true
    @State private var publicProfile = false
    @State private var friendsCanSeeTrips = true
    
    var body: some View {
        Form {
            Section("Privacy") {
                Toggle("Share Location Data", isOn: $shareLocation)
                Toggle("Public Profile", isOn: $publicProfile)
                Toggle("Friends Can See My Trips", isOn: $friendsCanSeeTrips)
            }
            
            Section {
                Text("Control who can see your vacation data and profile information.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    @State private var friendRequests = true
    @State private var newVacations = true
    @State private var tripReminders = false
    
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Friend Requests", isOn: $friendRequests)
                Toggle("New Vacations from Friends", isOn: $newVacations)
                Toggle("Trip Reminders", isOn: $tripReminders)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Roam")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            
            Section("About") {
                Text("Roam helps you visualize and share your vacation memories on an interactive globe. Upload photos from your trips and let AI generate beautiful itineraries.")
                    .font(.body)
            }
            
            Section {
                Link("Terms of Service", destination: URL(string: "https://roamapp.com/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://roamapp.com/privacy")!)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        Form {
            Section("Getting Started") {
                NavigationLink("How to Add Vacations") {
                    Text("Tutorial coming soon")
                }
                NavigationLink("Managing Friends") {
                    Text("Tutorial coming soon")
                }
                NavigationLink("Using the Map") {
                    Text("Tutorial coming soon")
                }
            }
            
            Section("Support") {
                Link("Contact Support", destination: URL(string: "mailto:support@roamapp.com")!)
                Link("Report a Bug", destination: URL(string: "https://roamapp.com/support")!)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
}

#Preview("Privacy") {
    NavigationStack {
        PrivacySettingsView()
    }
}

#Preview("About") {
    NavigationStack {
        AboutView()
    }
}

