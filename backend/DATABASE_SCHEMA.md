# Database Schema Documentation

This document describes the Supabase PostgreSQL database schema for the Roam backend API.

## Tables

### users

Stores user profile information.

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,  -- Matches Supabase Auth user ID
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    color TEXT NOT NULL,  -- Hex color for map pins (e.g., "#FF6B6B")
    profile_image TEXT,  -- URL to profile image
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### vacations

Stores vacation/trip information.

```sql
CREATE TABLE vacations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    ai_itinerary TEXT,  -- Generated narrative from Gemini
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_vacations_user_id ON vacations(user_id);
```

### locations

Stores specific locations within a vacation.

```sql
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vacation_id UUID NOT NULL REFERENCES vacations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    visit_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_locations_vacation_id ON locations(vacation_id);
CREATE INDEX idx_locations_coordinates ON locations USING GIST (
    ll_to_earth(latitude, longitude)
);  -- For geographic queries
```

### photos

Stores photo metadata and URLs.

```sql
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

CREATE INDEX idx_photos_location_id ON photos(location_id);
```

### activities

Stores activities at each location.

```sql
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    time TIMESTAMP WITH TIME ZONE,
    ai_generated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_activities_location_id ON activities(location_id);
```

### friends

Stores friend relationships and visibility settings.

```sql
CREATE TABLE friends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'accepted', 'rejected'
    is_visible BOOLEAN DEFAULT TRUE,  -- Show friend's vacations on map
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);

CREATE INDEX idx_friends_user_id ON friends(user_id);
CREATE INDEX idx_friends_friend_id ON friends(friend_id);
```

### articles (Optional)

Stores curated travel articles for locations.

```sql
CREATE TABLE articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    source TEXT,
    thumbnail_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_articles_location_id ON articles(location_id);
```

## Supabase Storage Buckets

### photos

Bucket for storing full-size photos and thumbnails.

**Structure:**
```
photos/
  {user_id}/
    {photo_id}.jpg
thumbnails/
  {user_id}/
    {photo_id}.jpg
```

**Configuration:**
- Public access: true
- File size limit: 10MB per file
- Allowed file types: image/jpeg, image/png, image/heic

## Row Level Security (RLS) Policies

Enable RLS on all tables and create policies:

### users table

```sql
-- Users can read their own profile
CREATE POLICY "Users can view own profile"
ON users FOR SELECT
USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = id);
```

### vacations table

```sql
-- Users can view their own vacations
CREATE POLICY "Users can view own vacations"
ON vacations FOR SELECT
USING (auth.uid() = user_id);

-- Users can view friends' vacations
CREATE POLICY "Users can view friends vacations"
ON vacations FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM friends
        WHERE (friends.user_id = auth.uid() AND friends.friend_id = vacations.user_id)
        AND friends.status = 'accepted'
        AND friends.is_visible = true
    )
);

-- Users can insert their own vacations
CREATE POLICY "Users can create own vacations"
ON vacations FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own vacations
CREATE POLICY "Users can update own vacations"
ON vacations FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own vacations
CREATE POLICY "Users can delete own vacations"
ON vacations FOR DELETE
USING (auth.uid() = user_id);
```

### locations, photos, activities tables

Similar policies cascade from vacations ownership.

### friends table

```sql
-- Users can view their own friendships
CREATE POLICY "Users can view own friendships"
ON friends FOR SELECT
USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Users can create friend requests
CREATE POLICY "Users can create friend requests"
ON friends FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can accept friend requests sent to them
CREATE POLICY "Users can accept friend requests"
ON friends FOR UPDATE
USING (auth.uid() = friend_id);

-- Users can delete their own friendships
CREATE POLICY "Users can delete friendships"
ON friends FOR DELETE
USING (auth.uid() = user_id OR auth.uid() = friend_id);
```

## Setup Instructions

1. Create a Supabase project at https://supabase.com

2. Run the SQL commands above in the Supabase SQL editor

3. Create storage bucket named "photos" with public access

4. Enable RLS on all tables

5. Copy your project URL and anon key to `.env`

## Migrations

For production, use Supabase migrations:

```bash
supabase init
supabase migration new create_tables
# Add SQL to migration file
supabase db push
```
