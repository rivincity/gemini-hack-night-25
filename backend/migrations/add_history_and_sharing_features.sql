-- TravelBuddy/Roam Database Migration
-- Adding Timeline, Sharing, and Memory Features
-- Date: 2025-11-04

-- ============================================
-- 1. ENHANCE VACATIONS TABLE
-- ============================================

-- Add new columns to vacations table
ALTER TABLE vacations
ADD COLUMN IF NOT EXISTS trip_name_ai TEXT,
ADD COLUMN IF NOT EXISTS summary TEXT,
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS share_code TEXT UNIQUE;

-- Add index for share_code lookups
CREATE INDEX IF NOT EXISTS idx_vacations_share_code ON vacations(share_code) WHERE share_code IS NOT NULL;

-- Add index for date-based queries
CREATE INDEX IF NOT EXISTS idx_vacations_start_date ON vacations(start_date);
CREATE INDEX IF NOT EXISTS idx_vacations_end_date ON vacations(end_date);
CREATE INDEX IF NOT EXISTS idx_vacations_dates ON vacations(start_date, end_date);

-- ============================================
-- 2. SHARED VACATIONS TABLE
-- ============================================

-- Granular sharing: Share specific vacations with specific friends
CREATE TABLE IF NOT EXISTS shared_vacations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vacation_id UUID NOT NULL REFERENCES vacations(id) ON DELETE CASCADE,
  shared_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  shared_with UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission TEXT NOT NULL DEFAULT 'view' CHECK (permission IN ('view', 'edit')),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(vacation_id, shared_with)
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_shared_vacations_vacation_id ON shared_vacations(vacation_id);
CREATE INDEX IF NOT EXISTS idx_shared_vacations_shared_with ON shared_vacations(shared_with);
CREATE INDEX IF NOT EXISTS idx_shared_vacations_shared_by ON shared_vacations(shared_by);

-- ============================================
-- 3. MEMORY HIGHLIGHTS TABLE
-- ============================================

-- AI-generated memory highlights for vacations
CREATE TABLE IF NOT EXISTS memory_highlights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vacation_id UUID NOT NULL REFERENCES vacations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  photo_id UUID REFERENCES photos(id) ON DELETE SET NULL,
  highlight_type TEXT, -- 'scenic_view', 'culinary_experience', 'adventure', 'cultural', 'social', 'best_moment'
  ai_confidence REAL DEFAULT 0.0, -- 0.0 to 1.0
  created_at TIMESTAMP DEFAULT NOW()
);

-- Index for fetching highlights by vacation
CREATE INDEX IF NOT EXISTS idx_memory_highlights_vacation_id ON memory_highlights(vacation_id);

-- ============================================
-- 4. VACATION TAGS TABLE
-- ============================================

-- Tags for better categorization and filtering
CREATE TABLE IF NOT EXISTS vacation_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vacation_id UUID NOT NULL REFERENCES vacations(id) ON DELETE CASCADE,
  tag TEXT NOT NULL, -- 'beach', 'adventure', 'cultural', 'food', 'city', 'nature', 'relaxation', 'shopping'
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(vacation_id, tag)
);

-- Index for tag-based queries
CREATE INDEX IF NOT EXISTS idx_vacation_tags_vacation_id ON vacation_tags(vacation_id);
CREATE INDEX IF NOT EXISTS idx_vacation_tags_tag ON vacation_tags(tag);

-- ============================================
-- 5. VACATION COLLABORATORS TABLE
-- ============================================

-- Support for collaborative trips (multiple users contribute)
CREATE TABLE IF NOT EXISTS vacation_collaborators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vacation_id UUID NOT NULL REFERENCES vacations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('owner', 'editor', 'viewer')),
  invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
  invited_at TIMESTAMP DEFAULT NOW(),
  accepted_at TIMESTAMP,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(vacation_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_vacation_collaborators_vacation_id ON vacation_collaborators(vacation_id);
CREATE INDEX IF NOT EXISTS idx_vacation_collaborators_user_id ON vacation_collaborators(user_id);
CREATE INDEX IF NOT EXISTS idx_vacation_collaborators_status ON vacation_collaborators(status);

-- ============================================
-- 6. TRIP STATISTICS MATERIALIZED VIEW
-- ============================================

-- Pre-computed statistics for faster timeline queries
CREATE MATERIALIZED VIEW IF NOT EXISTS user_travel_stats AS
SELECT
  u.id as user_id,
  COUNT(DISTINCT v.id) as total_trips,
  COUNT(DISTINCT l.id) as total_locations,
  COUNT(DISTINCT p.id) as total_photos,
  MIN(v.start_date) as first_trip_date,
  MAX(v.end_date) as last_trip_date,
  COUNT(DISTINCT EXTRACT(YEAR FROM v.start_date)) as years_traveled,
  ARRAY_AGG(DISTINCT EXTRACT(YEAR FROM v.start_date) ORDER BY EXTRACT(YEAR FROM v.start_date)) as travel_years
FROM users u
LEFT JOIN vacations v ON v.user_id = u.id
LEFT JOIN locations l ON l.vacation_id = v.id
LEFT JOIN photos p ON p.location_id = l.id
WHERE v.start_date IS NOT NULL
GROUP BY u.id;

-- Index for fast user lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_travel_stats_user_id ON user_travel_stats(user_id);

-- ============================================
-- 7. HELPER FUNCTIONS
-- ============================================

-- Function to refresh materialized view (call after vacation updates)
CREATE OR REPLACE FUNCTION refresh_user_travel_stats()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY user_travel_stats;
END;
$$ LANGUAGE plpgsql;

-- Function to generate share code
CREATE OR REPLACE FUNCTION generate_share_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  i INTEGER := 0;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. UPDATE EXISTING DATA
-- ============================================

-- Ensure all vacations have proper dates (use created_at if dates are null)
UPDATE vacations
SET start_date = created_at
WHERE start_date IS NULL;

UPDATE vacations
SET end_date = created_at
WHERE end_date IS NULL;

-- ============================================
-- 9. GRANT PERMISSIONS (if using RLS)
-- ============================================

-- Enable Row Level Security on new tables
ALTER TABLE shared_vacations ENABLE ROW LEVEL SECURITY;
ALTER TABLE memory_highlights ENABLE ROW LEVEL SECURITY;
ALTER TABLE vacation_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE vacation_collaborators ENABLE ROW LEVEL SECURITY;

-- RLS Policies for shared_vacations
CREATE POLICY shared_vacations_select_policy ON shared_vacations
  FOR SELECT USING (
    shared_with = auth.uid() OR
    shared_by = auth.uid() OR
    EXISTS (SELECT 1 FROM vacations v WHERE v.id = vacation_id AND v.user_id = auth.uid())
  );

CREATE POLICY shared_vacations_insert_policy ON shared_vacations
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM vacations v WHERE v.id = vacation_id AND v.user_id = auth.uid())
  );

CREATE POLICY shared_vacations_delete_policy ON shared_vacations
  FOR DELETE USING (
    shared_by = auth.uid() OR
    EXISTS (SELECT 1 FROM vacations v WHERE v.id = vacation_id AND v.user_id = auth.uid())
  );

-- RLS Policies for memory_highlights (only owner can see)
CREATE POLICY memory_highlights_select_policy ON memory_highlights
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM vacations v
      WHERE v.id = vacation_id AND (
        v.user_id = auth.uid() OR
        EXISTS (SELECT 1 FROM shared_vacations sv WHERE sv.vacation_id = v.id AND sv.shared_with = auth.uid())
      )
    )
  );

-- RLS Policies for vacation_tags (same as highlights)
CREATE POLICY vacation_tags_select_policy ON vacation_tags
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM vacations v
      WHERE v.id = vacation_id AND (
        v.user_id = auth.uid() OR
        EXISTS (SELECT 1 FROM shared_vacations sv WHERE sv.vacation_id = v.id AND sv.shared_with = auth.uid())
      )
    )
  );

-- RLS Policies for vacation_collaborators
CREATE POLICY vacation_collaborators_select_policy ON vacation_collaborators
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM vacations v WHERE v.id = vacation_id AND v.user_id = auth.uid())
  );

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

-- Refresh statistics view
SELECT refresh_user_travel_stats();

-- Verify migration
SELECT 'Migration completed successfully. New tables created:' as message;
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('shared_vacations', 'memory_highlights', 'vacation_tags', 'vacation_collaborators')
ORDER BY table_name;
