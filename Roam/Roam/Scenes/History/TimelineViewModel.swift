//
//  TimelineViewModel.swift
//  Roam
//
//  ViewModel for managing timeline data and travel statistics
//

import Foundation
import SwiftUI

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var timelineYears: [TimelineYearData] = []
    @Published var stats: TravelStatistics?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func loadTimeline() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch timeline data
            let timelineData: TimelineResponse = try await apiService.request(
                endpoint: "/history/timeline",
                method: .get,
                requiresAuth: false
            )

            // Convert to TimelineYearData array
            var yearsArray: [TimelineYearData] = []

            for (yearString, yearInfo) in timelineData.years {
                guard let year = Int(yearString) else { continue }

                let yearData = TimelineYearData(
                    year: year,
                    count: yearInfo.count,
                    vacations: yearInfo.vacations,
                    countries: yearInfo.countries,
                    cities: yearInfo.cities,
                    totalPhotos: yearInfo.totalPhotos
                )

                yearsArray.append(yearData)
            }

            // Sort by year descending (newest first)
            yearsArray.sort { $0.year > $1.year }

            self.timelineYears = yearsArray

            // Load statistics
            await loadStatistics()

        } catch {
            errorMessage = "Failed to load timeline: \(error.localizedDescription)"
            print("Timeline loading error: \(error)")
        }

        isLoading = false
    }

    func loadStatistics() async {
        do {
            let stats: TravelStatistics = try await apiService.request(
                endpoint: "/history/stats",
                method: .get,
                requiresAuth: false
            )

            self.stats = stats
        } catch {
            print("Failed to load statistics: \(error)")
        }
    }

    func applyDateFilter(from: Date, to: Date) async {
        isLoading = true

        do {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]

            let fromString = formatter.string(from: from).components(separatedBy: "T").first ?? ""
            let toString = formatter.string(from: to).components(separatedBy: "T").first ?? ""

            let response: FilteredVacationsResponse = try await apiService.request(
                endpoint: "/history/filter?from=\(fromString)&to=\(toString)",
                method: .get,
                requiresAuth: false
            )

            // Group vacations by year
            let groupedByYear = Dictionary(grouping: response.vacations) { vacation -> Int in
                guard let startDate = vacation.startDate else { return 0 }
                return Calendar.current.component(.year, from: startDate)
            }

            var yearsArray: [TimelineYearData] = []

            for (year, vacations) in groupedByYear where year > 0 {
                // Calculate stats for this year
                let countries = Set(vacations.flatMap { vacation in
                    vacation.locations.compactMap { location in
                        // Extract country from location name (assumes "City, Country" format)
                        let parts = location.name.split(separator: ",")
                        return parts.count >= 2 ? String(parts.last?.trimmingCharacters(in: .whitespaces) ?? "") : nil
                    }
                })

                let cities = Set(vacations.flatMap { vacation in
                    vacation.locations.compactMap { location in
                        let parts = location.name.split(separator: ",")
                        return parts.first.map { String($0.trimmingCharacters(in: .whitespaces)) }
                    }
                })

                let totalPhotos = vacations.reduce(0) { sum, vacation in
                    sum + vacation.locations.flatMap { $0.photos }.count
                }

                let yearData = TimelineYearData(
                    year: year,
                    count: vacations.count,
                    vacations: vacations,
                    countries: Array(countries),
                    cities: Array(cities),
                    totalPhotos: totalPhotos
                )

                yearsArray.append(yearData)
            }

            yearsArray.sort { $0.year > $1.year }
            self.timelineYears = yearsArray

        } catch {
            errorMessage = "Failed to filter: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func getYearsWithTrips() async -> [Int] {
        do {
            let response: YearsResponse = try await apiService.request(
                endpoint: "/history/years",
                method: .get,
                requiresAuth: false
            )

            return response.years
        } catch {
            print("Failed to get years: \(error)")
            return []
        }
    }
}

// MARK: - Response Models

struct TimelineResponse: Codable {
    let years: [String: YearInfo]
    let summary: TimelineSummary
}

struct YearInfo: Codable {
    let count: Int
    let vacations: [Vacation]
    let countries: [String]
    let cities: [String]
    let totalPhotos: Int

    enum CodingKeys: String, CodingKey {
        case count
        case vacations
        case countries
        case cities
        case totalPhotos = "total_photos"
    }
}

struct TimelineSummary: Codable {
    let totalTrips: Int
    let yearsCount: Int
    let earliestTrip: String?
    let latestTrip: String?

    enum CodingKeys: String, CodingKey {
        case totalTrips = "total_trips"
        case yearsCount = "years_count"
        case earliestTrip = "earliest_trip"
        case latestTrip = "latest_trip"
    }
}

struct TravelStatistics: Codable {
    let totalTrips: Int
    let countriesVisited: Int
    let citiesVisited: Int
    let yearsTraveling: [Int]
    let totalPhotos: Int
    let totalLocations: Int
    let favoriteDestinations: [String]
    let busiestYear: BusiestYear?
    let averageTripLengthDays: Double
    let totalDaysTraveled: Int

    enum CodingKeys: String, CodingKey {
        case totalTrips = "total_trips"
        case countriesVisited = "countries_visited"
        case citiesVisited = "cities_visited"
        case yearsTraveling = "years_traveling"
        case totalPhotos = "total_photos"
        case totalLocations = "total_locations"
        case favoriteDestinations = "favorite_destinations"
        case busiestYear = "busiest_year"
        case averageTripLengthDays = "average_trip_length_days"
        case totalDaysTraveled = "total_days_traveled"
    }
}

struct BusiestYear: Codable {
    let year: Int
    let trips: Int
}

struct FilteredVacationsResponse: Codable {
    let vacations: [Vacation]
    let count: Int
    let fromDate: String
    let toDate: String

    enum CodingKeys: String, CodingKey {
        case vacations
        case count
        case fromDate = "from_date"
        case toDate = "to_date"
    }
}

struct YearsResponse: Codable {
    let years: [Int]
    let count: Int
}
