# Friends Feature - No Authentication Setup

## Overview

The friends feature has been configured to work **without authentication** for easier testing and development. This means you can use all friend features without logging in.

## Changes Made

### Backend (`backend/app/routes/friends.py`)

All friend endpoints now have authentication **disabled**:

1. **`GET /api/friends`** - Get friends list
   - ❌ `@require_auth` commented out
   - ✅ Uses hardcoded `user_id = "demo-user-123"`

2. **`POST /api/friends/add`** - Send friend request
   - ❌ `@require_auth` commented out
   - ✅ Uses hardcoded `user_id = "demo-user-123"`

3. **`POST /api/friends/accept/:id`** - Accept friend request
   - ❌ `@require_auth` commented out
   - ✅ Uses hardcoded `user_id = "demo-user-123"`

4. **`DELETE /api/friends/:id`** - Remove friend
   - ❌ `@require_auth` commented out
   - ✅ Uses hardcoded `user_id = "demo-user-123"`

5. **`POST /api/friends/:id/toggle-visibility`** - Toggle visibility
   - ❌ `@require_auth` commented out
   - ✅ Uses hardcoded `user_id = "demo-user-123"`

6. **`GET /api/friends/:id/vacations`** - Get friend's vacations
   - ❌ `@require_auth` commented out
   - ✅ Uses hardcoded `user_id = "demo-user-123"`

### iOS App

All friend API calls now have `requiresAuth: false`:

**Updated in `Roam/Roam/Services/APIService.swift`:**
- `fetchFriends()` - No auth required
- `sendFriendRequest()` - No auth required
- `acceptFriendRequest()` - No auth required
- `removeFriend()` - No auth required
- `toggleFriendVisibility()` - No auth required
- `fetchAllVacationsWithFriends()` - No auth required for friend vacations

**Updated in `Roam/Roam/Scenes/Friends/FriendProfileView.swift`:**
- Friend vacation fetching - No auth required

## How It Works

### Single Demo User

All friend operations use the same demo user ID: `"demo-user-123"`

This means:
- ✅ You can add friends without logging in
- ✅ All friends are associated with the demo user
- ✅ You can see friends' vacations on the globe
- ✅ No authentication errors

### Testing Flow

1. **Open Friends Tab**
   - No login required!
   - View existing friends for demo user

2. **Add Friends**
   - Tap **+** button
   - Enter any email (must exist in database)
   - Friend request is sent

3. **View Friends' Vacations**
   - Friends' pins appear on globe
   - Color-coded by user
   - No auth errors

## Database Setup

For testing, you'll need some demo data in your Supabase database:

### Create Demo User

```sql
INSERT INTO users (id, email, name, color, created_at)
VALUES ('demo-user-123', 'demo@roam.app', 'Demo User', '#FF6B6B', NOW());
```

### Create Some Demo Friends

```sql
-- Friend 1
INSERT INTO users (id, email, name, color, created_at)
VALUES 
  ('friend-user-1', 'sarah@example.com', 'Sarah', '#4ECDC4', NOW()),
  ('friend-user-2', 'mike@example.com', 'Mike', '#95E1D3', NOW());

-- Add friendships
INSERT INTO friends (id, user_id, friend_id, status, is_visible, created_at)
VALUES 
  (gen_random_uuid(), 'demo-user-123', 'friend-user-1', 'accepted', true, NOW()),
  (gen_random_uuid(), 'demo-user-123', 'friend-user-2', 'accepted', true, NOW());
```

### Create Demo Vacations for Friends

```sql
-- Sarah's vacation
INSERT INTO vacations (id, user_id, title, start_date, end_date, created_at)
VALUES (gen_random_uuid(), 'friend-user-1', 'Tokyo Adventure', '2024-01-15', '2024-01-25', NOW());

-- Get the vacation ID and add a location
INSERT INTO locations (id, vacation_id, name, latitude, longitude, visit_date, created_at)
VALUES (gen_random_uuid(), 
  (SELECT id FROM vacations WHERE user_id = 'friend-user-1' LIMIT 1),
  'Tokyo, Japan', 35.6762, 139.6503, '2024-01-15', NOW());
```

## Re-enabling Authentication (Future)

When you're ready to add authentication back:

### Backend

1. Uncomment `@require_auth` decorators
2. Uncomment `user = get_current_user()` lines
3. Comment out hardcoded `user_id = "demo-user-123"`

Example:
```python
@bp.route('', methods=['GET'])
@require_auth  # ← Uncomment this
def get_friends():
    """Get user's friend list"""
    try:
        user = get_current_user()  # ← Uncomment this
        user_id = user.user.id      # ← Uncomment this
        # user_id = "demo-user-123"  # ← Comment this out
```

### iOS App

Change `requiresAuth: false` to `requiresAuth: true` in:
- `APIService.swift` - All friend methods
- `FriendProfileView.swift` - Friend vacations fetch

Example:
```swift
let response: FriendsResponse = try await request(
    endpoint: APIConfig.Endpoints.friends,
    method: .get,
    requiresAuth: true  // ← Change from false to true
)
```

## Benefits of No-Auth Mode

✅ **Faster Testing** - No need to sign up/login every time
✅ **Simpler Demo** - Show features immediately
✅ **Easier Development** - Focus on features, not auth flows
✅ **Shared Testing** - Everyone uses same demo user
✅ **No Token Issues** - No expired tokens or refresh logic

## Limitations

⚠️ **Single User** - All testers share the same demo user
⚠️ **No Privacy** - Everyone can see demo user's data
⚠️ **Production Risk** - Must re-enable auth before production
⚠️ **No User Isolation** - Can't test multi-user scenarios properly

## Current Status

🟢 **Friends Feature**: No authentication required
🟢 **Photo Upload**: No authentication required (already disabled)
🔴 **Vacations**: Still requires authentication (not changed)
🔴 **AI Services**: Still requires authentication (not changed)

## Summary

The friends feature now works completely without authentication! You can:
- ✅ View friends list
- ✅ Add friends by email or contacts
- ✅ Toggle friend visibility
- ✅ View friends' vacation pins on globe
- ✅ View friend profiles
- ✅ Accept/decline friend requests

All operations use the demo user `"demo-user-123"` - no login needed!

