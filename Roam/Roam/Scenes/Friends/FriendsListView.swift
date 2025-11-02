//
//  FriendsListView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI

struct FriendsListView: View {
    @State private var friends: [Friend] = []
    @State private var showAddFriend = false
    @State private var showFriendRequests = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading friends...")
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Error Loading Friends",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if friends.isEmpty {
                    ContentUnavailableView(
                        "No Friends Yet",
                        systemImage: "person.2",
                        description: Text("Add friends to see their vacation pins on the globe")
                    )
                } else {
                    List {
                        ForEach(friends) { friend in
                            NavigationLink(destination: FriendProfileView(friend: friend)) {
                                FriendRowView(friend: friend) { isVisible in
                                    toggleVisibility(for: friend, isVisible: isVisible)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    removeFriend(friend)
                                } label: {
                                    Label("Remove", systemImage: "person.badge.minus")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showFriendRequests = true }) {
                        Image(systemName: "tray")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddFriend = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView()
            }
            .sheet(isPresented: $showFriendRequests) {
                FriendRequestsView()
            }
            .onAppear {
                loadFriends()
            }
            .refreshable {
                await refreshFriends()
            }
        }
    }
    
    private func loadFriends() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                friends = try await APIService.shared.fetchFriends()
            } catch {
                errorMessage = "Failed to load friends: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func refreshFriends() async {
        do {
            friends = try await APIService.shared.fetchFriends()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to refresh friends: \(error.localizedDescription)"
        }
    }
    
    private func toggleVisibility(for friend: Friend, isVisible: Bool) {
        Task {
            do {
                try await APIService.shared.toggleFriendVisibility(
                    friendId: friend.userId,
                    isVisible: isVisible
                )
                
                // Update local state
                if let index = friends.firstIndex(where: { $0.id == friend.id }) {
                    friends[index] = Friend(
                        id: friend.id,
                        userId: friend.userId,
                        name: friend.name,
                        email: friend.email,
                        color: friend.color,
                        profileImage: friend.profileImage,
                        vacationCount: friend.vacationCount,
                        locationCount: friend.locationCount,
                        isVisible: isVisible
                    )
                }
            } catch {
                print("Failed to toggle visibility: \(error)")
            }
        }
    }
    
    private func removeFriend(_ friend: Friend) {
        Task {
            do {
                try await APIService.shared.removeFriend(friendId: friend.userId)
                
                // Remove from local list
                friends.removeAll { $0.id == friend.id }
            } catch {
                errorMessage = "Failed to remove friend: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Friend Row View
struct FriendRowView: View {
    let friend: Friend
    let onToggle: (Bool) -> Void
    @State private var isVisible: Bool
    
    init(friend: Friend, onToggle: @escaping (Bool) -> Void) {
        self.friend = friend
        self.onToggle = onToggle
        self._isVisible = State(initialValue: friend.isVisible)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(Color(hex: friend.color) ?? .blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(friend.name.prefix(1))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                
                Text("\(friend.vacationCount) trip\(friend.vacationCount != 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isVisible },
                set: { newValue in
                    isVisible = newValue
                    onToggle(newValue)
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FriendsListView()
}

