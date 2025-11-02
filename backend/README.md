# Roam Backend API

Backend API for the Roam iOS app - AI-powered vacation memory visualization on an interactive globe.

## Features

- **Supabase Authentication** - User signup, login, JWT token management
- **Batch Photo Upload** - Handle multiple photos from iOS albums at once
- **EXIF Extraction** - Automatically extract GPS coordinates and timestamps from photos
- **Gemini AI Integration** - Generate natural language itineraries from vacation photos
- **Vacation Management** - CRUD operations for vacations and locations
- **Social Features** - Friend management with visibility controls
- **Multimodal Processing** - Analyze images, text, and metadata together

## Tech Stack

- **Backend**: Python 3.10+ with Flask
- **Database**: Supabase (PostgreSQL)
- **Storage**: Supabase Storage
- **AI**: Google Gemini API (gemini-1.5-flash)
- **Image Processing**: Pillow (EXIF extraction, thumbnails)
- **Geocoding**: Geopy (Nominatim)

## Project Structure

```
backend/
├── app/
│   ├── __init__.py           # Flask app factory
│   ├── routes/               # API endpoints
│   │   ├── auth.py          # Authentication
│   │   ├── vacations.py     # Vacation CRUD
│   │   ├── photos.py        # Photo upload
│   │   ├── ai.py            # Gemini AI integration
│   │   └── friends.py       # Social features
│   ├── services/            # Business logic
│   │   ├── supabase_service.py
│   │   ├── gemini_service.py
│   │   ├── exif_service.py
│   │   └── geocoding_service.py
│   └── middleware/
│       └── auth_middleware.py
├── requirements.txt
├── .env.example
├── run.py
└── DATABASE_SCHEMA.md
```

## Setup Instructions

### 1. Clone Repository

```bash
cd backend
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Set Up Supabase

1. Create a project at https://supabase.com
2. Run the SQL from `DATABASE_SCHEMA.md` in the SQL editor
3. Create a storage bucket named "photos" (public access)
4. Copy your project URL and anon key

### 4. Set Up Gemini API

1. Get API key from https://ai.google.dev/
2. Copy to `.env` file

### 5. Configure Environment

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env`:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key
GEMINI_API_KEY=your-gemini-api-key
```

### 6. Run the Server

```bash
python run.py
```

Server will start on `http://localhost:5000`

## API Documentation

Base URL: `http://localhost:5000/api`

### Authentication

#### Sign Up

```http
POST /api/auth/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}
```

Response:
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "color": "#FF6B6B"
  },
  "session": {
    "access_token": "jwt-token",
    "refresh_token": "refresh-token"
  }
}
```

#### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### Get Current User

```http
GET /api/auth/me
Authorization: Bearer <token>
```

### Photos

#### Batch Upload Photos

```http
POST /api/photos/upload/batch
Authorization: Bearer <token>
Content-Type: multipart/form-data

photos: [file1, file2, file3, ...]
```

Response:
```json
{
  "photos": [
    {
      "id": "photo-uuid",
      "imageURL": "https://...",
      "thumbnailURL": "https://...",
      "captureDate": "2024-10-01T14:30:00Z",
      "location": {
        "latitude": 48.8566,
        "longitude": 2.3522
      },
      "hasExif": true
    }
  ],
  "count": 10
}
```

#### Upload Single Photo

```http
POST /api/photos/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

photo: <file>
```

### AI Itinerary Generation

#### Generate Itinerary from Photos

```http
POST /api/ai/generate-itinerary
Authorization: Bearer <token>
Content-Type: application/json

{
  "photos": [
    {
      "imageURL": "https://...",
      "captureDate": "2024-10-01T14:30:00Z",
      "coordinates": {
        "latitude": 48.8566,
        "longitude": 2.3522
      }
    }
  ],
  "title": "European Adventure"
}
```

Response:
```json
{
  "vacation": {
    "id": "vacation-uuid",
    "title": "European Adventure",
    "startDate": "2024-10-01T00:00:00Z",
    "endDate": "2024-10-10T00:00:00Z",
    "aiGeneratedItinerary": "Your European adventure began in Paris...",
    "locations": [
      {
        "id": "loc-uuid",
        "name": "Paris, France",
        "coordinate": {
          "latitude": 48.8566,
          "longitude": 2.3522
        },
        "visitDate": "2024-10-01T00:00:00Z",
        "photos": [],
        "activities": [
          {
            "id": "act-uuid",
            "title": "Explored Paris, France",
            "description": "Visited and captured memories",
            "aiGenerated": true
          }
        ]
      }
    ]
  }
}
```

### Vacations

#### Get All Vacations

```http
GET /api/vacations
Authorization: Bearer <token>
```

Returns user's vacations + visible friends' vacations.

#### Get Vacation Details

```http
GET /api/vacations/<vacation_id>
Authorization: Bearer <token>
```

#### Create Vacation

```http
POST /api/vacations
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Summer Trip",
  "startDate": "2024-07-01T00:00:00Z",
  "endDate": "2024-07-15T00:00:00Z"
}
```

#### Update Vacation

```http
PUT /api/vacations/<vacation_id>
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Updated Title"
}
```

#### Delete Vacation

```http
DELETE /api/vacations/<vacation_id>
Authorization: Bearer <token>
```

### Friends

#### Get Friends List

```http
GET /api/friends
Authorization: Bearer <token>
```

Response:
```json
{
  "friends": [
    {
      "id": "user-uuid",
      "name": "Sarah",
      "color": "#4ECDC4",
      "vacationCount": 3,
      "locationCount": 8,
      "isVisible": true
    }
  ]
}
```

#### Add Friend

```http
POST /api/friends/add
Authorization: Bearer <token>
Content-Type: application/json

{
  "email": "friend@example.com"
}
```

#### Accept Friend Request

```http
POST /api/friends/accept/<friendship_id>
Authorization: Bearer <token>
```

#### Remove Friend

```http
DELETE /api/friends/<friend_id>
Authorization: Bearer <token>
```

#### Toggle Friend Visibility

```http
POST /api/friends/<friend_id>/toggle-visibility
Authorization: Bearer <token>
Content-Type: application/json

{
  "isVisible": false
}
```

## How It Works

### Photo Processing Pipeline

1. **iOS uploads batch of photos** → `/api/photos/upload/batch`
2. **Extract EXIF data** (GPS, timestamp) from each photo in parallel
3. **Generate thumbnails** (300x300)
4. **Upload to Supabase Storage** (original + thumbnail)
5. **Return metadata** with public URLs

### AI Itinerary Generation

1. **Receive photos with EXIF** → `/api/ai/generate-itinerary`
2. **Cluster photos by location** (within 10km using Haversine distance)
3. **Reverse geocode coordinates** to location names
4. **Build prompt** with location summaries and dates
5. **Call Gemini API** to generate natural language narrative
6. **Parse response** into structured activities
7. **Save to database** (vacation, locations, activities, photos)
8. **Return complete vacation** JSON matching iOS models

### Architecture Flow

```
iOS App
   ↓ (Select photos from album)
   ↓
POST /photos/upload/batch
   ↓ (Parallel processing)
   ├─ Extract EXIF (GPS + timestamp)
   ├─ Create thumbnail
   └─ Upload to Supabase Storage
   ↓
POST /ai/generate-itinerary
   ↓
   ├─ Cluster locations
   ├─ Geocode coordinates
   ├─ Call Gemini API
   └─ Structure data
   ↓
Save to Database
   ├─ vacations table
   ├─ locations table
   ├─ activities table
   └─ photos table
   ↓
Return JSON to iOS
```

## Error Handling

All endpoints return standard JSON error responses:

```json
{
  "error": "Error message description"
}
```

HTTP Status Codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Development

### Running in Debug Mode

```bash
export FLASK_DEBUG=True
python run.py
```

### Testing with Postman

1. Import endpoints into Postman
2. Set up environment variable for auth token
3. Test authentication flow first
4. Use returned token for protected endpoints

### Database Migrations

See `DATABASE_SCHEMA.md` for full schema and RLS policies.

## Deployment

### Deploy to Railway

1. Install Railway CLI:
   ```bash
   npm i -g @railway/cli
   ```

2. Login and init:
   ```bash
   railway login
   railway init
   ```

3. Add environment variables in Railway dashboard

4. Deploy:
   ```bash
   railway up
   ```

### Deploy to Google Cloud Run

1. Build container:
   ```bash
   gcloud builds submit --tag gcr.io/PROJECT-ID/roam-api
   ```

2. Deploy:
   ```bash
   gcloud run deploy roam-api \
     --image gcr.io/PROJECT-ID/roam-api \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated
   ```

## Troubleshooting

### EXIF Not Found

Some photos may not have GPS data. The API will handle this gracefully and skip those photos when clustering locations.

### Gemini API Rate Limits

Free tier: 15 requests per minute. For high traffic, upgrade to paid tier.

### Supabase Storage Issues

Ensure the "photos" bucket has public read access enabled.

## Contributing

This is a hackathon project. Feel free to fork and improve!

## License

MIT
