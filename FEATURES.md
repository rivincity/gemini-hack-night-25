# Roam - Feature Specifications

## Core Features Implemented

### 1. Interactive Globe View 🌍
**File**: `GlobeViewController.swift`

**Features**:
- MapKit-based world map showing all vacation locations
- Custom pin annotations with user-specific colors
- Smooth zoom and pan interactions
- Floating action buttons for key actions

**UI Elements**:
- Friends button (top-right): Access friends list
- Add vacation button (bottom-right): Upload new vacation photos
- Map pins: Color-coded by user, tap to view details

**User Flow**:
1. App opens to world view showing all pins
2. User can pan/zoom to explore different locations
3. Tap any pin to see vacation details
4. Use buttons to manage friends or add new vacations

---

### 2. Pin Detail View 📍
**File**: `PinDetailViewController.swift`

**Features**:
- Location header with name, date, and owner
- Photo album access button
- Google Flights integration button
- AI-generated itinerary section
- Recommended articles section

**UI Components**:
- **Header Card**: Location name, visit date, trip owner with color indicator
- **Action Buttons**:
  - "View Photo Album": Opens photo gallery (your trips only)
  - "Book Flights to [Location]": Opens Google Flights in Safari
- **Itinerary Cards**: Activity timeline with AI-generated suggestions
  - 🤖 icon for AI-generated activities
  - 📝 icon for manual entries
  - Time, title, and description for each activity
- **Article Cards**: Curated travel content
  - Clickable cards opening in Safari
  - Source attribution

**User Flow**:
1. Tap a pin on the map
2. View detailed location information
3. Browse AI-generated itinerary
4. Access photo album (if owner)
5. Book flights or read articles
6. Close to return to map

---

### 3. Friends Management 👥
**File**: `FriendsViewController.swift`

**Features**:
- Friends list with color-coded indicators
- Visibility toggles for each friend
- Vacation count display
- Add friend functionality (UI ready)

**UI Components**:
- **Friend Cells**:
  - Color indicator circle with icon
  - Friend name
  - Trip and location count
  - Visibility toggle switch
- **Header**: "Your Friends"
- **Footer**: Usage instructions
- **Add Button**: Navbar button to add new friends

**User Flow**:
1. Tap friends button on main map
2. View list of all friends
3. Toggle visibility switches to show/hide pins
4. Tap friend to view their profile
5. Add new friends (coming soon)

---

### 4. User Profile View 👤
**File**: `FriendsViewController.swift` (UserProfileViewController)

**Features**:
- User vacation history
- Trip list with dates
- Navigation to specific locations

**UI Components**:
- Table view of all vacations
- Vacation title and date range
- Color-coded icons
- Disclosure indicators for navigation

**User Flow**:
1. Tap a friend in friends list
2. View their vacation history
3. Tap a vacation to see location details
4. Navigate back to friends or map

---

## Data Models

### User
```swift
- id: UUID
- name: String
- color: String (hex)
- vacations: [Vacation]
```

### Vacation
```swift
- id: UUID
- title: String
- startDate: Date
- endDate: Date
- locations: [VacationLocation]
- photoAlbumURL: String?
- aiGeneratedItinerary: String?
```

### VacationLocation
```swift
- id: UUID
- name: String
- coordinate: Coordinate
- visitDate: Date
- photos: [Photo]
- activities: [Activity]
- articles: [Article]
```

### Photo
```swift
- id: UUID
- imageURL: String
- captureDate: Date
- location: Coordinate?
- caption: String?
```

### Activity
```swift
- id: UUID
- title: String
- description: String
- time: Date
- aiGenerated: Bool
```

### Article
```swift
- id: UUID
- title: String
- url: String
- source: String
```

---

## Mock Data

The app includes three sample users:

### You (Red: #FF6B6B)
- **European Adventure**: Paris → Rome
- Activities: Eiffel Tower visit, Colosseum tour

### Sarah (Teal: #4ECDC4)
- **Asian Journey**: Tokyo
- Activities: Shibuya Crossing

### Mike (Mint: #95E1D3)
- **South American Trek**: Machu Picchu
- Activities: Inca Trail hike

---

## External Integrations

### Google Flights
- Deep link format: `https://www.google.com/flights?q=flights+to+[location]`
- Opens in Safari View Controller
- Automatic city name extraction from location

### Travel Articles
- Google Search integration for travel content
- Categories: Things to do, Restaurants, Hidden gems
- Opens in Safari View Controller

---

## Design System

### Colors
- **Primary**: System Blue
- **Secondary**: System Green
- **Background**: System Background (adaptive)
- **User Colors**: Custom hex colors for identification

### Typography
- **Headers**: SF Pro Display, Bold, 20-24pt
- **Body**: SF Pro Text, Regular, 14-17pt
- **Captions**: SF Pro Text, Regular, 12-14pt

### Icons
- SF Symbols throughout
- Custom emoji for activities and users
- Consistent 40-60pt button sizes

### Layout
- 16-20pt margins
- 12pt spacing between elements
- Rounded corners (10-12pt radius)
- Subtle shadows for elevation

---

## Technical Implementation

### Architecture
- **Pattern**: MVC (Model-View-Controller)
- **UI Framework**: UIKit
- **Maps**: MapKit
- **Web Views**: SafariServices

### Key Technologies
- `MKMapView`: Interactive map display
- `MKAnnotation`: Custom pin annotations
- `UITableView`: Lists and scrolling content
- `UIScrollView`: Detail view content
- `SFSafariViewController`: External links

### Protocols
- `FriendsViewControllerDelegate`: Friend visibility updates
- `FriendCellDelegate`: Cell interaction handling

### Extensions
- `String.hexToUIColor()`: Hex color conversion

---

## Future Enhancements

### Phase 2: Photo Upload
- Photo picker integration
- EXIF metadata extraction
- Location and timestamp parsing
- Album organization

### Phase 3: AI Integration
- Gemini API integration
- Itinerary generation from photos
- Activity recognition
- Smart suggestions

### Phase 4: Social Features
- User authentication
- Friend requests and management
- Privacy controls
- Push notifications

### Phase 5: Advanced Features
- Offline mode
- PDF export
- Travel statistics
- Route visualization
- Multi-day trip planning

---

## Testing Checklist

- [ ] Map loads and displays pins correctly
- [ ] Pin colors match user assignments
- [ ] Tap pin opens detail view
- [ ] Friends list displays all users
- [ ] Visibility toggles update map
- [ ] Google Flights link opens correctly
- [ ] Article links open in Safari
- [ ] Photo album shows appropriate message
- [ ] Navigation flows work smoothly
- [ ] UI adapts to different screen sizes

---

Built with attention to detail and user experience in mind! 🚀

