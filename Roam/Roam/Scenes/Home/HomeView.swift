//
//  HomeView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI

struct HomeView: View {
    @State private var showAddVacation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Wrap UIKit GlobeViewController
                GlobeViewControllerRepresentable()
                    .ignoresSafeArea()
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddVacation = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.blue)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Roam")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddVacation) {
                AddVacationView()
            }
        }
    }
}

// MARK: - UIKit Wrapper for GlobeViewController
struct GlobeViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GlobeViewController {
        return GlobeViewController()
    }
    
    func updateUIViewController(_ uiViewController: GlobeViewController, context: Context) {
        // Update if needed
    }
}

#Preview {
    HomeView()
}

