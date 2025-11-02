//
//  VacationDetailView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI

struct VacationDetailView: View {
    let vacation: Vacation
    let user: User
    
    var body: some View {
        List {
            Section("Trip Information") {
                LabeledContent("Duration", value: dateRangeString)
                LabeledContent("Locations", value: "\(vacation.locations.count)")
            }
            
            Section("Locations") {
                ForEach(vacation.locations) { location in
                    NavigationLink(destination: LocationDetailView(location: location, vacation: vacation, user: user)) {
                        LocationRowView(location: location)
                    }
                }
            }
        }
        .navigationTitle(vacation.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: vacation.startDate)) - \(formatter.string(from: vacation.endDate))"
    }
}

// MARK: - Location Row View
struct LocationRowView: View {
    let location: VacationLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                Text(location.name)
                    .font(.headline)
            }
            
            Text(dateString)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !location.activities.isEmpty {
                Text("\(location.activities.count) activit\(location.activities.count != 1 ? "ies" : "y")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: location.visitDate)
    }
}

#Preview {
    NavigationStack {
        VacationDetailView(
            vacation: User.mockUsers[0].vacations[0],
            user: User.mockUsers[0]
        )
    }
}

