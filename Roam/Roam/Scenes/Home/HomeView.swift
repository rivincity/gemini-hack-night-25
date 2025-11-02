//
//  HomeView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct HomeView: View {
    @State private var showAddVacation = false
    @State private var selectedVacationItem: VacationSheetItem?
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
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // SwiftUI MapKit with Globe mode
                Map(position: $cameraPosition) {
                    ForEach(annotations) { annotation in
                        Annotation(annotation.title, coordinate: annotation.coordinate) {
                            Button(action: {
                                selectedVacationItem = VacationSheetItem(vacation: annotation.vacation, user: annotation.user)
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
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddVacation) {
                AddVacationView(onVacationCreated: loadAnnotations)
            }
            .sheet(item: $selectedVacationItem) { item in
                NavigationStack {
                    VacationDetailView(vacation: item.vacation, user: item.user)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    selectedVacationItem = nil
                                }
                            }
                        }
                }
            }
            .onAppear {
                loadAnnotations()
            }
        }
    }
    
    private func loadAnnotations() {
        print("🗺️ [HomeView] Loading annotations from API...")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                print("🌐 [HomeView] Fetching vacations from backend...")
                let vacations = try await APIService.shared.fetchVacations()
                print("✅ [HomeView] Fetched \(vacations.count) vacations")

                // Build annotations from real vacation data
                var newAnnotations: [VacationAnnotationItem] = []

                for vacation in vacations {
                    print("📍 [HomeView] Processing vacation: \(vacation.title) with \(vacation.locations.count) locations")

                    for location in vacation.locations {
                        // Create a user object from the vacation owner
                        let user = User(
                            id: vacation.owner?.id ?? UUID(),
                            name: vacation.owner?.name ?? "Unknown",
                            color: vacation.owner?.color ?? "#FF6B6B",
                            vacations: [vacation]
                        )

                        let annotation = VacationAnnotationItem(
                            id: location.id,
                            title: location.name,
                            coordinate: location.coordinate.clCoordinate,
                            color: Color(hex: vacation.owner?.color ?? "#FF6B6B") ?? .blue,
                            location: location,
                            vacation: vacation,
                            user: user
                        )

                        newAnnotations.append(annotation)
                    }
                }

                print("✅ [HomeView] Created \(newAnnotations.count) annotations")

                await MainActor.run {
                    annotations = newAnnotations
                    isLoading = false
                }

            } catch {
                print("❌ [HomeView] Error loading vacations: \(error)")
                print("⚠️ [HomeView] Falling back to mock data")

                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false

                    // Fallback to mock data on error
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

// MARK: - Vacation Sheet Item (for sheet presentation)
struct VacationSheetItem: Identifiable {
    let id: UUID
    let vacation: Vacation
    let user: User
    
    init(vacation: Vacation, user: User) {
        self.id = vacation.id
        self.vacation = vacation
        self.user = user
    }
}

#Preview {
    HomeView()
}

