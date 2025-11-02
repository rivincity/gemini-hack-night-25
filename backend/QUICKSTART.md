# Quick Start Guide

Get the Roam backend API running in 5 minutes!

## Prerequisites

- Python 3.10+
- pip
- Supabase account
- Google Gemini API key

## Step 1: Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

## Step 2: Set Up Supabase

1. Go to https://supabase.com and create a new project
2. Wait for project to finish setting up (2-3 minutes)
3. Go to **SQL Editor** and run this:

```sql
-- Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    color TEXT NOT NULL,
    profile_image TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create vacations table
CREATE TABLE vacations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    ai_itinerary TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create locations table
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vacation_id UUID NOT NULL REFERENCES vacations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    visit_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create photos table
CREATE TABLE photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    capture_date TIMESTAMP WITH TIME ZONE,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    caption TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create activities table
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    time TIMESTAMP WITH TIME ZONE,
    ai_generated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create friends table
CREATE TABLE friends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending',
    is_visible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);
```

4. Go to **Storage** and create a bucket named `photos` with **Public** access
5. Copy your **Project URL** and **anon key** from **Settings > API**

## Step 3: Get Gemini API Key

1. Go to https://ai.google.dev/
2. Click "Get API key" and create one
3. Copy the API key

## Step 4: Configure Environment

```bash
cp .env.example .env
```

Edit `.env` file:

```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
GEMINI_API_KEY=AIzaSyD...
```

## Step 5: Run the Server

```bash
python run.py
```

You should see:

```
Starting Roam API server on 0.0.0.0:5000
 * Running on http://127.0.0.1:5000
```

## Step 6: Test It!

Open another terminal and test the health endpoint:

```bash
curl http://localhost:5000/api/health
```

You should get:

```json
{"status":"ok","message":"Roam API is running"}
```

## Step 7: Test Authentication

Create a user:

```bash
curl -X POST http://localhost:5000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'
```

You should get back a user object with an access token!

## Next Steps

1. Read `README.md` for full API documentation
2. Check `DATABASE_SCHEMA.md` for database details
3. Test photo upload with Postman or curl
4. Integrate with your iOS app!

## Common Issues

**Import Error**: Make sure you're in the `backend` directory and have activated your virtual environment

**Supabase Connection Error**: Double-check your `.env` file has the correct URL and key

**Gemini API Error**: Verify your API key is valid and has not exceeded rate limits

**Module Not Found**: Run `pip install -r requirements.txt` again

## Need Help?

Check the full README.md or the iOS app integration guide!
