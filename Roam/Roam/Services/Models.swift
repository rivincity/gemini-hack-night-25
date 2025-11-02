//
//  Models.swift
//  Roam
//
//  Created by Eswar Karavadi on 11/2/25.
//

import Foundation
import UIKit
import CoreLocation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var profileImage: String?
    var color: String // Hex color for pin identification
    var vacations: [Vacation]
    
    init(id: UUID = UUID(), name: String, color: String, vacations: [Vacation] = []) {
        self.id = id
        self.name = name
        self.color = color
        self.vacations = vacations
    }
}

// MARK: - Vacation Model
struct Vacation: Identifiable, Codable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var locations: [VacationLocation]
    var photoAlbumURL: String?
    var aiGeneratedItinerary: String?
    
    init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date, locations: [VacationLocation] = []) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.locations = locations
    }
}

// MARK: - Vacation Location Model
struct VacationLocation: Identifiable, Codable {
    let id: UUID
    var name: String
    var coordinate: Coordinate
    var visitDate: Date
    var photos: [Photo]
    var activities: [Activity]
    var articles: [Article]
    
    init(id: UUID = UUID(), name: String, coordinate: Coordinate, visitDate: Date, photos: [Photo] = [], activities: [Activity] = []) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.visitDate = visitDate
        self.photos = photos
        self.activities = activities
        self.articles = []
    }
}

// MARK: - Coordinate Model
struct Coordinate: Codable {
    var latitude: Double
    var longitude: Double
    
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Photo Model
struct Photo: Identifiable, Codable {
    let id: UUID
    var imageURL: String
    var thumbnailURL: String?
    var captureDate: Date
    var location: Coordinate?
    var caption: String?
    
    init(id: UUID = UUID(), imageURL: String, captureDate: Date, location: Coordinate? = nil) {
        self.id = id
        self.imageURL = imageURL
        self.captureDate = captureDate
        self.location = location
    }
}

// MARK: - Activity Model
struct Activity: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var time: Date
    var aiGenerated: Bool
    
    init(id: UUID = UUID(), title: String, description: String, time: Date, aiGenerated: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.time = time
        self.aiGenerated = aiGenerated
    }
}

// MARK: - Article Model
struct Article: Identifiable, Codable {
    let id: UUID
    var title: String
    var url: String
    var source: String
    var thumbnailURL: String?
    
    init(id: UUID = UUID(), title: String, url: String, source: String) {
        self.id = id
        self.title = title
        self.url = url
        self.source = source
    }
}

// MARK: - Mock Data
extension User {
    static var mockUsers: [User] {
        [
            User(
                name: "You",
                color: "#FF6B6B",
                vacations: [
                    Vacation(
                        title: "European Adventure",
                        startDate: Date().addingTimeInterval(-60*60*24*30),
                        endDate: Date().addingTimeInterval(-60*60*24*20),
                        locations: [
                            VacationLocation(
                                name: "Paris, France",
                                coordinate: Coordinate(latitude: 48.8566, longitude: 2.3522),
                                visitDate: Date().addingTimeInterval(-60*60*24*30),
                                photos: [
                                    Photo(imageURL: "eiffel_tower", captureDate: Date().addingTimeInterval(-60*60*24*30))
                                ],
                                activities: [
                                    Activity(title: "Eiffel Tower Visit", description: "Visited the iconic Eiffel Tower at sunset", time: Date().addingTimeInterval(-60*60*24*30), aiGenerated: true)
                                ]
                            ),
                            VacationLocation(
                                name: "Rome, Italy",
                                coordinate: Coordinate(latitude: 41.9028, longitude: 12.4964),
                                visitDate: Date().addingTimeInterval(-60*60*24*25),
                                photos: [
                                    Photo(imageURL: "colosseum", captureDate: Date().addingTimeInterval(-60*60*24*25))
                                ],
                                activities: [
                                    Activity(title: "Colosseum Tour", description: "Explored ancient Roman history", time: Date().addingTimeInterval(-60*60*24*25), aiGenerated: true)
                                ]
                            )
                        ]
                    )
                ]
            ),
            User(
                name: "Sarah",
                color: "#4ECDC4",
                vacations: [
                    Vacation(
                        title: "Asian Journey",
                        startDate: Date().addingTimeInterval(-60*60*24*45),
                        endDate: Date().addingTimeInterval(-60*60*24*35),
                        locations: [
                            VacationLocation(
                                name: "Tokyo, Japan",
                                coordinate: Coordinate(latitude: 35.6762, longitude: 139.6503),
                                visitDate: Date().addingTimeInterval(-60*60*24*45),
                                photos: [],
                                activities: [
                                    Activity(title: "Shibuya Crossing", description: "Experienced the famous crossing", time: Date().addingTimeInterval(-60*60*24*45), aiGenerated: true)
                                ]
                            )
                        ]
                    )
                ]
            ),
            User(
                name: "Mike",
                color: "#95E1D3",
                vacations: [
                    Vacation(
                        title: "South American Trek",
                        startDate: Date().addingTimeInterval(-60*60*24*60),
                        endDate: Date().addingTimeInterval(-60*60*24*50),
                        locations: [
                            VacationLocation(
                                name: "Machu Picchu, Peru",
                                coordinate: Coordinate(latitude: -13.1631, longitude: -72.5450),
                                visitDate: Date().addingTimeInterval(-60*60*24*55),
                                photos: [],
                                activities: [
                                    Activity(title: "Inca Trail Hike", description: "Hiked the ancient Inca trail", time: Date().addingTimeInterval(-60*60*24*55), aiGenerated: true)
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    }
}

