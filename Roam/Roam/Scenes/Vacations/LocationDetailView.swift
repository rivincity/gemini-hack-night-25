//
//  LocationDetailView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI

struct LocationDetailView: View {
    let location: VacationLocation
    let vacation: Vacation
    let user: User
    
    var body: some View {
        // Wrap UIKit PinDetailViewController
        PinDetailViewControllerRepresentable(
            location: location,
            vacation: vacation,
            user: user
        )
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - UIKit Wrapper for PinDetailViewController
struct PinDetailViewControllerRepresentable: UIViewControllerRepresentable {
    let location: VacationLocation
    let vacation: Vacation
    let user: User
    
    func makeUIViewController(context: Context) -> PinDetailViewController {
        return PinDetailViewController(location: location, vacation: vacation, user: user)
    }
    
    func updateUIViewController(_ uiViewController: PinDetailViewController, context: Context) {
        // Update if needed
    }
}

#Preview {
    NavigationStack {
        LocationDetailView(
            location: User.mockUsers[0].vacations[0].locations[0],
            vacation: User.mockUsers[0].vacations[0],
            user: User.mockUsers[0]
        )
    }
}

