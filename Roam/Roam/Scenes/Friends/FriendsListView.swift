//
//  FriendsListView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI

struct FriendsListView: View {
    @State private var friends: [User] = User.mockUsers
    @State private var showAddFriend = false
    @State private var visibleFriends: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(friends) { friend in
                    NavigationLink(destination: FriendProfileView(user: friend)) {
                        FriendRowView(user: friend, isVisible: visibleFriends.contains(friend.id)) {
                            toggleVisibility(for: friend)
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddFriend = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView()
            }
            .onAppear {
                // Initialize all friends as visible
                visibleFriends = Set(friends.map { $0.id })
            }
        }
    }
    
    private func toggleVisibility(for user: User) {
        if visibleFriends.contains(user.id) {
            visibleFriends.remove(user.id)
        } else {
            visibleFriends.insert(user.id)
        }
    }
}

// MARK: - Friend Row View
struct FriendRowView: View {
    let user: User
    let isVisible: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(Color(hex: user.color) ?? .blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(user.name.prefix(1))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                
                Text("\(user.vacations.count) trip\(user.vacations.count != 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isVisible },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FriendsListView()
}

