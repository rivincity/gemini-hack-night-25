//
//  HomeView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI
import MapKit

struct HomeView: View {
    @State private var showAddVacation = false
    @State private var cameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
            distance: 40000000, // Very far out to trigger globe mode
            heading: 0,
            pitch: 0
        )
    )
    @State private var annotations: [VacationAnnotationItem] = []
    @State private var mapCameraPosition = MapCameraPosition.automatic
    
    var body: some View {
        NavigationStack {
            ZStack {
                // SwiftUI MapKit with Globe mode
                Map(position: $cameraPosition) {
                    ForEach(annotations) { annotation in
                        Annotation(annotation.title, coordinate: annotation.coordinate) {
                            Button(action: {
                                // TODO: Show detail view
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(annotation.color)
                                        .frame(width: 30, height: 30)
                                    Image(systemName: "airplane.circle.fill")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddVacation = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
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
            .onAppear {
                loadAnnotations()
            }
        }
    }
    
    private func loadAnnotations() {
        // Load vacation pins from mock data
        annotations = User.mockUsers.flatMap { user in
            user.vacations.flatMap { vacation in
                vacation.locations.map { location in
                    VacationAnnotationItem(
                        id: location.id,
                        title: location.name,
                        coordinate: location.coordinate.clCoordinate,
                        color: Color(hex: user.color) ?? .blue,
                        location: location,
                        vacation: vacation,
                        user: user
                    )
                }
            }
        }
    }
}

// MARK: - Vacation Annotation Item
struct VacationAnnotationItem: Identifiable {
    let id: UUID
    let title: String
    let coordinate: CLLocationCoordinate2D
    let color: Color
    let location: VacationLocation
    let vacation: Vacation
    let user: User
}

#Preview {
    HomeView()
}

