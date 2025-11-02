//
//  FriendProfileView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI

struct FriendProfileView: View {
    let user: User
    
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color(hex: user.color) ?? .blue)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(user.name.prefix(1))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(user.vacations.count) vacation\(user.vacations.count != 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            
            Section("Vacations") {
                if user.vacations.isEmpty {
                    Text("No vacations yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(user.vacations) { vacation in
                        NavigationLink(destination: VacationDetailView(vacation: vacation, user: user)) {
                            VacationRowView(vacation: vacation)
                        }
                    }
                }
            }
        }
        .navigationTitle(user.name)
        .navigationBarTitleDisplayMode(.inline)
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
        return "\(formatter.string(from: vacation.startDate)) - \(formatter.string(from: vacation.endDate))"
    }
}

#Preview {
    NavigationStack {
        FriendProfileView(user: User.mockUsers[0])
    }
}

