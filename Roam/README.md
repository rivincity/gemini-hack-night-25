# Roam - Vacation Memory & Travel Planning App

Roam is an iOS app that helps you visualize and share your vacation memories on an interactive globe. Upload photos from your trips, and let AI generate beautiful itineraries based on your photo metadata.

## Features

### 🌍 Interactive Globe View
- Beautiful map interface showing all vacation locations
- Color-coded pins for different users
- Tap any pin to explore vacation details

### 📸 Photo-Based Itinerary Creation
- Upload vacation photos with metadata (location, date, time)
- AI analyzes photos to generate detailed itineraries
- Automatic activity detection and timeline creation

### 👥 Friends & Social Features
- Add friends and view their vacation pins
- Color-coded pins for easy identification
- Toggle friend visibility on the map
- View friends' vacation details and itineraries

### ✈️ Travel Planning Integration
- Direct links to Google Flights for booking
- Curated travel articles for each destination
- Photo album access for your own trips

## Current Implementation (Mockup)

This initial commit includes:

### Data Models (`Models.swift`)
- `User`: User profiles with color-coded identification
- `Vacation`: Trip information with dates and locations
- `VacationLocation`: Individual destinations with coordinates
- `Photo`: Photo metadata including capture date and location
- `Activity`: AI-generated or manual activities
- `Article`: Travel articles and recommendations

### Views

#### `GlobeViewController`
- Main map view with interactive pins
- Friends button to manage connections
- Add vacation button for photo uploads
- Custom pin annotations with user colors

#### `PinDetailViewController`
- Location details and visit dates
- AI-generated itinerary display
- Photo album access button
- Google Flights integration
- Recommended articles section

#### `FriendsViewController`
- Friends list with visibility toggles
- Color-coded friend indicators
- Vacation count display
- Add friend functionality (coming soon)

#### `UserProfileViewController`
- User vacation history
- Trip timeline view

## Mock Data

The app includes sample data showing:
- Your vacation to Paris and Rome
- Sarah's trip to Tokyo
- Mike's adventure to Machu Picchu

## Future Features

- [ ] Photo upload and metadata extraction
- [ ] AI-powered itinerary generation using Gemini
- [ ] Real-time friend management
- [ ] Photo album creation and sharing
- [ ] Offline mode support
- [ ] Export itineraries as PDF
- [ ] Travel statistics and insights

## Technical Stack

- **Language**: Swift
- **UI Framework**: UIKit
- **Maps**: MapKit
- **Minimum iOS**: iOS 14.0+

## Getting Started

1. Open `Roam.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run (⌘R)

## Architecture

The app follows a clean MVC architecture:
- **Models**: Data structures and mock data
- **Views**: Custom UI components and cells
- **Controllers**: View controllers managing UI logic

## Design Highlights

- Modern iOS design with system colors and SF Symbols
- Smooth animations and transitions
- Responsive layout supporting all iPhone sizes
- Accessibility-friendly with proper labels and hints

## License

This project is part of the Gemini Hack Night 2025.

---

Built with ❤️ for travelers who want to remember and share their adventures.

