//
//  AddFriendView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                } else if searchText.isEmpty {
                    ContentUnavailableView(
                        "Find Friends",
                        systemImage: "person.2.fill",
                        description: Text("Enter a username or email to find friends")
                    )
                } else {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("No users found matching '\(searchText)'")
                    )
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Username or email")
            .onChange(of: searchText) { oldValue, newValue in
                if !newValue.isEmpty {
                    performSearch()
                }
            }
        }
    }
    
    private func performSearch() {
        // TODO: Implement friend search
        isSearching = true
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isSearching = false
        }
    }
}

#Preview {
    AddFriendView()
}

