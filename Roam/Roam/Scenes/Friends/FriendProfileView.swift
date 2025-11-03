//
//  FriendProfileView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI

struct FriendProfileView: View {
    let friend: Friend
    @State private var vacations: [Vacation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color(hex: friend.color) ?? .blue)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(friend.name.prefix(1))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text(friend.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let email = friend.email {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(friend.vacationCount) vacation\(friend.vacationCount != 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            
            Section("Vacations") {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .italic()
                } else if vacations.isEmpty {
                    Text("No vacations yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(vacations) { vacation in
                        VacationRowView(vacation: vacation)
                    }
                }
            }
        }
        .navigationTitle(friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFriendVacations()
        }
    }
    
    private func loadFriendVacations() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let endpoint = "\(APIConfig.baseURL)\(APIConfig.apiVersion)/friends/\(friend.userId.uuidString)/vacations"
                
                struct FriendVacationsResponse: Codable {
                    let vacations: [Vacation]
                }
                
                let response: FriendVacationsResponse = try await APIService.shared.request(
                    endpoint: endpoint,
                    method: .get,
                    requiresAuth: false  // No auth required for testing
                )
                
                vacations = response.vacations
            } catch {
                errorMessage = "Failed to load vacations: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}

// MARK: - Vacation Row View
struct VacationRowView: View {
    let vacation: Vacation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "airplane.circle.fill")
                    .foregroundColor(.blue)
                Text(vacation.title)
                    .font(.headline)
            }
            
            Text(dateRangeString)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !vacation.locations.isEmpty {
                Text("\(vacation.locations.count) location\(vacation.locations.count != 1 ? "s" : "")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if let startDate = vacation.startDate, let endDate = vacation.endDate {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        } else {
            return "Dates not specified"
        }
    }
}

#Preview {
    NavigationStack {
        FriendProfileView(friend: Friend(
            userId: UUID(),
            name: "Sarah",
            email: "sarah@example.com",
            color: "#4ECDC4",
            vacationCount: 3,
            locationCount: 5
        ))
    }
}

