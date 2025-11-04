//
//  TimelineView.swift
//  Roam
//
//  Timeline view showing user's travel history organized by year
//

import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
    @State private var searchText = ""
    @State private var showFilterSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    LoadingView(message: "Loading your travel history...")
                } else if viewModel.timelineYears.isEmpty {
                    EmptyStateView(
                        icon: "globe",
                        title: "No Travel History Yet",
                        subtitle: "Start building your travel archive by uploading your first vacation photos"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Stats Header
                            if let stats = viewModel.stats {
                                TravelStatsHeaderView(stats: stats)
                                    .padding()
                            }

                            // Timeline List
                            LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                                ForEach(filteredYears, id: \.year) { yearData in
                                    Section {
                                        ForEach(yearData.vacations, id: \.id) { vacation in
                                            NavigationLink(destination: VacationDetailView(vacation: vacation)) {
                                                TimelineVacationRowView(vacation: vacation)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    } header: {
                                        YearHeaderView(yearData: yearData)
                                            .background(.ultraThinMaterial)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("My Travel History")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search locations...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheet(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.loadTimeline()
            }
            .task {
                await viewModel.loadTimeline()
            }
        }
    }

    private var filteredYears: [TimelineYearData] {
        if searchText.isEmpty {
            return viewModel.timelineYears
        }

        return viewModel.timelineYears.compactMap { yearData in
            let filteredVacations = yearData.vacations.filter { vacation in
                vacation.title.localizedCaseInsensitiveContains(searchText) ||
                vacation.locations.contains { location in
                    location.name.localizedCaseInsensitiveContains(searchText)
                }
            }

            if filteredVacations.isEmpty {
                return nil
            }

            return TimelineYearData(
                year: yearData.year,
                count: filteredVacations.count,
                vacations: filteredVacations,
                countries: yearData.countries,
                cities: yearData.cities,
                totalPhotos: yearData.totalPhotos
            )
        }
    }
}

// MARK: - Timeline Year Data

struct TimelineYearData: Identifiable {
    let year: Int
    let count: Int
    let vacations: [Vacation]
    let countries: [String]
    let cities: [String]
    let totalPhotos: Int

    var id: Int { year }
}

// MARK: - Year Header View

struct YearHeaderView: View {
    let yearData: TimelineYearData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(yearData.year)")
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 12) {
                    Label("\(yearData.count) trip\(yearData.count == 1 ? "" : "s")", systemImage: "airplane")
                    Label("\(yearData.countries.count) countr\(yearData.countries.count == 1 ? "y" : "ies")", systemImage: "globe")
                    Label("\(yearData.totalPhotos) photo\(yearData.totalPhotos == 1 ? "" : "s")", systemImage: "photo")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Timeline Vacation Row

struct TimelineVacationRowView: View {
    let vacation: Vacation

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            if let firstPhoto = vacation.locations.first?.photos.first {
                AsyncImage(url: URL(string: firstPhoto.thumbnailURL ?? firstPhoto.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(Image(systemName: "photo"))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "photo"))
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Trip name with icon
                HStack(spacing: 6) {
                    Image(systemName: tripIcon)
                        .font(.caption)
                        .foregroundColor(Color(hex: vacation.owner?.color ?? "#FF6B6B"))

                    Text(vacation.title)
                        .font(.headline)
                        .lineLimit(1)
                }

                // Date range
                if let startDate = vacation.startDate {
                    Text(formatDateRange(start: startDate, end: vacation.endDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Locations
                if !vacation.locations.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text("\(vacation.locations.count) location\(vacation.locations.count == 1 ? "" : "s")")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var tripIcon: String {
        // Determine icon based on trip type or locations
        let locationNames = vacation.locations.map { $0.name.lowercased() }

        if locationNames.contains(where: { $0.contains("beach") || $0.contains("island") }) {
            return "beach.umbrella"
        } else if locationNames.contains(where: { $0.contains("mountain") || $0.contains("alps") }) {
            return "mountain.2"
        } else if locationNames.contains(where: { $0.contains("city") || $0.contains("paris") || $0.contains("tokyo") }) {
            return "building.2"
        } else {
            return "airplane"
        }
    }

    private func formatDateRange(start: Date, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if let end = end, !Calendar.current.isDate(start, inSameDayAs: end) {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else {
            return formatter.string(from: start)
        }
    }
}

// MARK: - Travel Stats Header

struct TravelStatsHeaderView: View {
    let stats: TravelStatistics

    var body: some View {
        VStack(spacing: 16) {
            // Main stats
            HStack(spacing: 20) {
                StatCard(value: "\(stats.totalTrips)", label: "Trips", icon: "airplane")
                StatCard(value: "\(stats.countriesVisited)", label: "Countries", icon: "globe")
                StatCard(value: "\(stats.citiesVisited)", label: "Cities", icon: "mappin.circle")
            }

            // Years traveling
            if !stats.yearsTraveling.isEmpty {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text("Traveling since \(stats.yearsTraveling.first ?? 2020)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let busiest = stats.busiestYear {
                        Text("Busiest: \(busiest.year) (\(busiest.trips) trips)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @ObservedObject var viewModel: TimelineViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedFromDate = Date().addingTimeInterval(-365*24*60*60) // 1 year ago
    @State private var selectedToDate = Date()
    @State private var includeFriends = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("From", selection: $selectedFromDate, displayedComponents: .date)
                    DatePicker("To", selection: $selectedToDate, displayedComponents: .date)

                    Button("Show All Time") {
                        selectedFromDate = Date().addingTimeInterval(-10*365*24*60*60) // 10 years ago
                        selectedToDate = Date()
                    }
                }

                Section("Include") {
                    Toggle("Friends' Vacations", isOn: $includeFriends)
                }

                Section {
                    Button("Apply Filters") {
                        Task {
                            await viewModel.applyDateFilter(from: selectedFromDate, to: selectedToDate)
                            dismiss()
                        }
                    }

                    Button("Reset") {
                        Task {
                            await viewModel.loadTimeline()
                            dismiss()
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Filter Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TimelineView()
}
