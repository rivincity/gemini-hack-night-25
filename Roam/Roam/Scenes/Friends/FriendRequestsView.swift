//
//  FriendRequestsView.swift
//  Roam
//
//  Friend requests management view
//

import SwiftUI

struct FriendRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pendingRequests: [FriendRequest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading requests...")
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Error Loading Requests",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if pendingRequests.isEmpty {
                    ContentUnavailableView(
                        "No Pending Requests",
                        systemImage: "tray",
                        description: Text("You don't have any pending friend requests")
                    )
                } else {
                    List {
                        ForEach(pendingRequests) { request in
                            FriendRequestRow(request: request) { action in
                                handleAction(for: request, action: action)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadPendingRequests()
            }
        }
    }
    
    private func loadPendingRequests() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // TODO: Implement API call to fetch pending requests
                // For now, using mock data
                pendingRequests = []
            } catch {
                errorMessage = "Failed to load requests: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func handleAction(for request: FriendRequest, action: FriendRequestAction) {
        Task {
            do {
                switch action {
                case .accept:
                    try await APIService.shared.acceptFriendRequest(friendshipId: request.id)
                    pendingRequests.removeAll { $0.id == request.id }
                case .reject:
                    // TODO: Implement reject endpoint
                    pendingRequests.removeAll { $0.id == request.id }
                }
            } catch {
                errorMessage = "Failed to process request: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Friend Request Row
struct FriendRequestRow: View {
    let request: FriendRequest
    let onAction: (FriendRequestAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: request.friendColor) ?? .blue)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(request.friendName.prefix(1))
                            .font(.title3)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.friendName)
                        .font(.headline)
                    
                    Text("Sent \(timeAgo(from: request.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: { onAction(.accept) }) {
                    Text("Accept")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Button(action: { onAction(.reject) }) {
                    Text("Decline")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

enum FriendRequestAction {
    case accept
    case reject
}

#Preview {
    FriendRequestsView()
}

