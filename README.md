# Roam - AI-Powered Vacation Memory Sharing

**Built for Gemini Hack Night 2025**

Created by Rivan Parikh, Samik Wangneo, Eswar Karavadi, Purab Shah

---

## 🌍 What We Built

A complete full-stack iOS app that transforms your vacation photos into AI-generated itineraries and visualizes them on an interactive 3D globe. Upload photos, and Roam automatically:

- 📸 Extracts GPS coordinates and timestamps from EXIF data
- 🤖 Uses Google Gemini AI to analyze photos and generate detailed itineraries
- 🗺️ Places vacation pins on a realistic 3D globe
- 👥 Lets you share vacations with friends and view their trips
- ✈️ Integrates flight booking and travel article recommendations

## ✨ Features

### Core Functionality

- **Photo Upload & Processing**: Batch upload with EXIF metadata extraction (GPS, timestamps)
- **AI Itinerary Generation**: Google Gemini multimodal AI analyzes photos and creates day-by-day narratives
- **3D Globe Visualization**: Interactive MapKit globe with color-coded vacation pins
- **Social Sharing**: Add friends from contacts, toggle visibility, view their vacations
- **Location Intelligence**: Automatic reverse geocoding from coordinates to location names
- **Smart Photo Grouping**: Clusters photos by location proximity and sorts by time

### iOS App

- SwiftUI + UIKit hybrid architecture
- PhotosUI integration for multi-photo selection
- Contact picker for friend invitations
- Core Location for "navigate to me" feature
- Pull-to-refresh for real-time updates
- Offline-capable with mock data fallback

## 🛠 Tech Stack

### Backend

- **Framework**: Python 3.11 + Flask
- **Database**: Supabase (PostgreSQL + Auth + Storage)
- **AI/ML**: Google Gemini API (multimodal vision + text)
- **Image Processing**: Pillow (EXIF extraction, thumbnail generation)
- **Geocoding**: Geopy (coordinates → location names)
- **Storage**: Supabase Storage (S3-compatible)

### iOS

- **Language**: Swift 5.9+
- **Minimum iOS**: 17.0+
- **UI**: SwiftUI (primary) + UIKit (legacy views)
- **Frameworks**: MapKit, PhotosUI, Contacts, CoreLocation

## 📁 Project Structure

```
gemini-hack-night-25/
├── backend/                      # Python Flask API
│   ├── app/
│   │   ├── __init__.py          # Flask app factory + demo user setup
│   │   ├── routes/              # API endpoints
│   │   │   ├── auth.py          # Signup, login, logout
│   │   │   ├── vacations.py    # Vacation CRUD
│   │   │   ├── photos.py        # Photo upload, EXIF extraction
│   │   │   ├── ai.py            # Gemini AI itinerary generation
│   │   │   └── friends.py       # Social features
│   │   ├── services/            # Business logic
│   │   │   ├── gemini_service.py      # AI processing
│   │   │   ├── supabase_service.py    # DB & storage client
│   │   │   ├── exif_service.py        # Photo metadata
│   │   │   └── geocoding_service.py   # Location names
│   │   ├── middleware/
│   │   │   └── auth_middleware.py     # JWT verification
│   │   └── utils/
│   │       └── helpers.py
│   ├── requirements.txt
│   ├── run.py                   # Server entry point
│   ├── DATABASE_SCHEMA.md       # Database documentation
│   └── .env (you create this)
│
└── Roam/                         # iOS App
    ├── Roam/
    │   ├── RoamApp.swift        # App entry point
    │   ├── Scenes/              # SwiftUI views
    │   │   ├── Home/
    │   │   │   ├── HomeView.swift          # 3D globe
    │   │   │   └── AddVacationView.swift   # Photo upload
    │   │   ├── Friends/
    │   │   │   ├── FriendsListView.swift
    │   │   │   ├── AddFriendView.swift
    │   │   │   └── FriendRequestsView.swift
    │   │   ├── Vacations/
    │   │   │   ├── VacationDetailView.swift
    │   │   │   └── LocationDetailView.swift
    │   │   ├── Authentication/
    │   │   │   ├── LoginView.swift
    │   │   │   └── RegisterView.swift
    │   │   └── Profile/
    │   ├── Services/            # API integration
    │   │   ├── APIService.swift      # HTTP client
    │   │   ├── AuthService.swift     # Auth state
    │   │   ├── APIConfig.swift       # Endpoints
    │   │   └── Models.swift          # Data models
    │   ├── Components/          # Reusable UI
    │   │   ├── ContactPickerView.swift
    │   │   └── ColorExtension.swift
    │   └── Info.plist           # Permissions
    └── Roam.xcodeproj
```

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Xcode 15+ (for iOS)
- Supabase account
- Google Gemini API key

### Backend Setup

1. **Navigate to backend directory**

```bash
cd backend
```

2. **Create and activate virtual environment**

```bash
python3.11 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. **Install dependencies**

```bash
pip install -r requirements.txt
```

4. **Create environment file**

```bash
# Create .env file with:
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key
GEMINI_API_KEY=your-gemini-api-key
```

5. **Set up Supabase**

Create a project at [supabase.com](https://supabase.com), then:

**a) Create Storage Bucket:**

- Go to Storage → Create bucket
- Name: `photos`
- Make it public

**b) Run SQL in SQL Editor:**

```sql
-- Create demo user (UUID format required)
INSERT INTO users (id, email, name, color, created_at)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'demo@roam.app',
    'Demo User',
    '#FF6B6B',
    NOW()
)
ON CONFLICT (id) DO NOTHING;
```

Tables are auto-created by the app, or you can manually create them using `DATABASE_SCHEMA.md`.

6. **Run the server**

```bash
python run.py
```

Server runs at `http://localhost:5000`

### iOS App Setup

1. **Open Xcode project**

```bash
cd Roam
open Roam.xcodeproj
```

2. **Update API endpoint**

Open `Roam/Services/APIConfig.swift` and set:

```swift
static let baseURL = "http://localhost:5000"  // or your ngrok URL
```

3. **Build and run**

- Select target device/simulator
- Press `Cmd+R`

## 📡 API Endpoints

### Authentication

```
POST   /api/auth/signup          Register new user
POST   /api/auth/login           Login user
GET    /api/auth/me              Get current user info
POST   /api/auth/logout          Logout user
```

### Photos & Upload

```
POST   /api/photos/upload/batch  Upload multiple photos (multipart/form-data)
POST   /api/photos/upload        Upload single photo
GET    /api/photos/:vacation_id  Get photos for vacation
```

### AI / Itinerary Generation

```
POST   /api/ai/generate-itinerary
  Body: {
    "title": "Iceland Trip",
    "photos": [
      {
        "imageURL": "https://...",
        "thumbnailURL": "https://...",
        "captureDate": "2024-08-08T17:55:30Z",
        "location": { "latitude": 63.5314, "longitude": -19.5112 },
        "hasExif": true
      }
    ]
  }
  Response: { "vacation": {...}, "message": "..." }

POST   /api/ai/analyze-photo      Analyze single photo with Gemini
```

### Vacations

```
GET    /api/vacations             Get user's vacations + visible friends
GET    /api/vacations/:id         Get vacation details with locations
POST   /api/vacations             Create vacation manually
PUT    /api/vacations/:id         Update vacation
DELETE /api/vacations/:id         Delete vacation
```

### Friends & Social

```
GET    /api/friends                        Get friend list
POST   /api/friends/add                    Send friend request (by email)
POST   /api/friends/accept/:id             Accept friend request
DELETE /api/friends/:id                    Remove friend
POST   /api/friends/:id/toggle-visibility  Show/hide friend's pins
GET    /api/friends/:id/vacations          Get friend's vacations
```

### Health Check

```
GET    /api/health                Server status
```

## 🗄 Database Schema

### Tables

**users** - User profiles

- `id` UUID (primary key)
- `email` TEXT (unique)
- `name` TEXT
- `color` TEXT (hex color for pins)
- `profile_image` TEXT (optional)
- `created_at` TIMESTAMP

**vacations** - Trip records

- `id` UUID (primary key)
- `user_id` UUID → users
- `title` TEXT
- `start_date` TIMESTAMP
- `end_date` TIMESTAMP
- `ai_itinerary` TEXT (AI-generated narrative)
- `created_at`, `updated_at` TIMESTAMP

**locations** - Places visited

- `id` UUID (primary key)
- `vacation_id` UUID → vacations
- `name` TEXT
- `latitude`, `longitude` DOUBLE
- `visit_date` TIMESTAMP
- `created_at` TIMESTAMP

**photos** - Vacation photos

- `id` UUID (primary key)
- `location_id` UUID → locations
- `image_url` TEXT (full-size)
- `thumbnail_url` TEXT
- `capture_date` TIMESTAMP
- `latitude`, `longitude` DOUBLE (from EXIF)
- `caption` TEXT
- `created_at` TIMESTAMP

**activities** - Things to do

- `id` UUID (primary key)
- `location_id` UUID → locations
- `title` TEXT
- `description` TEXT
- `time` TIMESTAMP
- `ai_generated` BOOLEAN
- `created_at` TIMESTAMP

**friends** - Social connections

- `id` UUID (primary key)
- `user_id` UUID → users
- `friend_id` UUID → users
- `status` TEXT (pending/accepted/rejected)
- `is_visible` BOOLEAN (show on map)
- `created_at` TIMESTAMP

## 🔄 How It Works

### 1. Photo Upload Flow

```
User selects photos in iOS app
    ↓
PhotosPicker extracts image data + EXIF metadata
    ↓
Multipart/form-data POST to /api/photos/upload/batch
    ↓
Backend extracts GPS coordinates, timestamps
    ↓
Generates 300x300 thumbnails
    ↓
Uploads to Supabase Storage
    ↓
Returns photo URLs + metadata
```

### 2. AI Itinerary Generation

```
Frontend calls /api/ai/generate-itinerary with photo metadata
    ↓
Backend groups photos by location (within ~5km)
    ↓
Sends photo URLs + coordinates to Gemini AI
    ↓
Gemini analyzes images and generates narrative itinerary
    ↓
Backend parses response into locations + activities
    ↓
Reverse geocodes coordinates to location names
    ↓
Stores vacation, locations, activities, photos in DB
    ↓
Returns complete vacation object to iOS
```

### 3. Globe Visualization

```
iOS app calls /api/vacations (includes friends' vacations)
    ↓
Receives array of vacations with locations
    ↓
Extracts GPS coordinates for each location
    ↓
Places color-coded pins on MapKit globe
    ↓
User taps pin → Shows vacation detail sheet
```

### 4. Friends Feature

```
User adds friend by email or from contacts
    ↓
Backend checks if email exists in users table
    ↓
Creates friendship record with status='pending'
    ↓
Friend accepts request
    ↓
Status → 'accepted', is_visible=true by default
    ↓
Friend's vacation pins appear on requester's globe
```

## 🎨 Demo Mode (No Authentication)

Currently runs in **demo mode** for easy testing:

- Demo user UUID: `00000000-0000-0000-0000-000000000001`
- No login required
- All operations use demo user
- Authentication decorators commented out

**To re-enable auth:**

1. Uncomment `@require_auth` in route files
2. Update iOS app: `requiresAuth: true` in API calls
3. Implement signup/login flow

## 🧪 Testing

### Test Backend

```bash
# Health check
curl http://localhost:5000/api/health

# Upload photos
curl -X POST http://localhost:5000/api/photos/upload/batch \
  -F "title=Iceland Trip" \
  -F "photos=@photo1.jpg" \
  -F "photos=@photo2.jpg"

# Generate itinerary
curl -X POST http://localhost:5000/api/ai/generate-itinerary \
  -H "Content-Type: application/json" \
  -d '{"title": "My Trip", "photos": [...]}'
```

### Test iOS App

1. Launch in Simulator
2. Tap "+" button on globe
3. Select vacation photos
4. Enter trip name
5. Tap "Create Vacation"
6. Wait for AI to generate itinerary
7. View vacation on globe

## 🎯 Key Implementation Details

### EXIF Metadata Extraction

- Uses Pillow library to extract GPS coordinates
- Handles JPEG, PNG, HEIC formats
- Preserves metadata during iOS PhotosPicker transfer
- Falls back gracefully if EXIF data missing

### Gemini AI Integration

- Multimodal API (vision + text)
- Processes multiple photos simultaneously
- Generates natural language itineraries
- Extracts structured data (locations, activities, timestamps)
- Rate limiting and error handling

### Smart Photo Grouping

- Clusters photos within ~10km radius
- Sorts by capture timestamp
- Auto-generates location names from coordinates
- Creates one VacationLocation per cluster

### iOS Globe Rendering

- Uses MapKit with `.hybrid(elevation: .realistic)` style
- Triggers globe mode with high zoom distance (40,000 km)
- Color-coded pins per user (from profile color)
- Smooth animations for navigation

## 🔒 Security Notes

**Current State (Demo Mode):**

- ⚠️ No authentication enforced
- ⚠️ Single demo user for all operations
- ⚠️ Suitable for demos and testing only

**Production Recommendations:**

- ✅ Enable Supabase Row Level Security (RLS)
- ✅ Validate JWT tokens on all protected routes
- ✅ Add rate limiting on AI endpoints
- ✅ Validate file uploads (size, type, content)
- ✅ Sanitize all user inputs
- ✅ Use HTTPS only
- ✅ Store API keys securely (never commit)

## 📦 Dependencies

### Backend (`requirements.txt`)

```
flask==3.0.0
flask-cors==4.0.0
supabase==2.3.4
python-dotenv==1.0.0
google-generativeai==0.3.2
Pillow==10.2.0
geopy==2.4.1
requests==2.31.0
python-dateutil==2.8.2
```

### iOS

- Built-in frameworks (no external dependencies)
- SwiftUI, MapKit, PhotosUI, Contacts, CoreLocation

## 🚀 Deployment

### Backend (Railway/Render/Heroku)

```bash
# Set environment variables in platform dashboard:
- SUPABASE_URL
- SUPABASE_KEY
- GEMINI_API_KEY

# Build command
pip install -r requirements.txt

# Start command
python run.py
```

### iOS (TestFlight/App Store)

1. Update bundle identifier
2. Configure signing & capabilities
3. Set production API endpoint in `APIConfig.swift`
4. Archive and upload to App Store Connect

## 🔮 Future Enhancements

### Planned Features

- [ ] Push notifications for friend requests
- [ ] Collaborative vacations (multiple contributors)
- [ ] Photo comments and reactions
- [ ] Travel statistics dashboard
- [ ] Export itinerary as PDF
- [ ] Public vacation sharing links
- [ ] Offline mode with sync
- [ ] Budget tracking per trip
- [ ] Weather information per location
- [ ] Restaurant/hotel recommendations

### AI Enhancements

- [ ] Detect subjects in photos (landmarks, people)
- [ ] Auto-suggest activity categories
- [ ] Multi-language itinerary generation
- [ ] Budget estimation from photos
- [ ] Travel style recommendations

## 🤝 Team

- **Rivan Parikh** - iOS Development
- **Samik Wangneo** - Backend Development
- **Eswar Karavadi** - iOS Development
- **Purab Shah** - Backend & AI Integration

## 📄 License

MIT License - Built for Gemini Hack Night 2025

## 🙏 Acknowledgments

- **Google Gemini AI** - Multimodal image analysis and itinerary generation
- **Supabase** - Database, authentication, and storage infrastructure
- **Apple** - SwiftUI, MapKit, and iOS frameworks
- **Flask** - Lightweight and powerful Python web framework

---

**🌍 Happy Roaming! ✈️**

Built with ❤️ for travelers who want to relive and share their adventures.
