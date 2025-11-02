//
//  HomeView.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

// ✅ Fix: Make CLLocationCoordinate2D Equatable
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct HomeView: View {
    @State private var showAddVacation = false
    @State private var selectedVacationItem: VacationSheetItem?
    @StateObject private var locationManager = LocationManager()
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
    @State private var isLoadingVacations = false
    @State private var useMockData = true // Fallback to mock data if API fails
    
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
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                
                // Custom Location Button (top right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: navigateToUserLocation) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }
                    Spacer()
                }
                
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
                AddVacationView()
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
            .refreshable {
                await refreshVacations()
            }
            .onChange(of: locationManager.location) { oldValue, newValue in
                // Navigate when location becomes available and we're waiting for it
                if let newLocation = newValue,
                   locationManager.shouldNavigateWhenLocationAvailable,
                   oldValue == nil || oldValue?.coordinate != newLocation.coordinate {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        cameraPosition = .camera(
                            MapCamera(
                                centerCoordinate: newLocation.coordinate,
                                distance: 10000000,
                                heading: 0,
                                pitch: 0
                            )
                        )
                    }
                    locationManager.shouldNavigateWhenLocationAvailable = false
                }
            }
        }
    }
    
    private func loadAnnotations() {
        isLoadingVacations = true
        
        Task {
            do {
                // Try to fetch from API
                let vacationsWithUsers = try await APIService.shared.fetchAllVacationsWithFriends()
                
                // Convert to annotations
                annotations = vacationsWithUsers.flatMap { (vacation, user) in
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
                
                useMockData = false
                print("✅ Loaded \(annotations.count) vacation pins from API")
            } catch {
                print("❌ Failed to load vacations from API: \(error)")
                
                // Fallback to mock data
                if useMockData {
                    loadMockAnnotations()
                }
            }
            
            isLoadingVacations = false
        }
    }
    
    private func loadMockAnnotations() {
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
        print("📍 Loaded \(annotations.count) vacation pins from mock data")
    }
    
    private func refreshVacations() async {
        do {
            let vacationsWithUsers = try await APIService.shared.fetchAllVacationsWithFriends()
            
            annotations = vacationsWithUsers.flatMap { (vacation, user) in
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
            
            useMockData = false
            print("🔄 Refreshed \(annotations.count) vacation pins")
        } catch {
            print("❌ Failed to refresh vacations: \(error)")
        }
    }
    
    private func navigateToUserLocation() {
        if let location = locationManager.location {
            // Navigate to user's location with a closer zoom level
            withAnimation(.easeInOut(duration: 1.0)) {
                cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: location.coordinate,
                        distance: 10000000, // Closer zoom to see more detail (10,000 km)
                        heading: 0,
                        pitch: 0
                    )
                )
            }
        } else {
            // Request location if not available
            locationManager.shouldNavigateWhenLocationAvailable = true
            locationManager.requestLocation()
        }
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var shouldNavigateWhenLocationAvailable = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
        // Navigation will be handled by HomeView observing location changes via onChange
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        shouldNavigateWhenLocationAvailable = false
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if shouldNavigateWhenLocationAvailable {
                manager.requestLocation()
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
