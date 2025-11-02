# Friends Feature - Complete Implementation

## Overview

The Roam app now supports adding friends from your phone contacts, sending invitations, and viewing friends' vacation pins on the globe. This feature integrates seamlessly with the existing backend API and provides a rich social experience.

## Features Implemented

### 1. **Contact Integration**
- ✅ Access phone contacts with proper permissions
- ✅ Search and filter contacts
- ✅ Select contacts to add as friends or invite

### 2. **Friend Management**
- ✅ Add friends by email address
- ✅ Add friends from phone contacts
- ✅ View friends list with vacation counts
- ✅ Toggle friend visibility (show/hide their pins on globe)
- ✅ Remove friends (swipe to delete)
- ✅ View friend profiles with their vacations

### 3. **Invitations**
- ✅ Send email invitations to non-users
- ✅ Send SMS invitations to non-users
- ✅ Automatic detection if contact is already on Roam

### 4. **Friend Requests**
- ✅ View pending friend requests
- ✅ Accept/decline friend requests
- ✅ Friend request notifications UI

### 5. **Globe Integration**
- ✅ Display friends' vacation pins on the globe
- ✅ Different colors for each friend (based on user profile color)
- ✅ Filter visible friends' vacations
- ✅ Pull to refresh vacations

## Files Created/Modified

### New Files
1. **`Roam/Roam/Components/ContactPickerView.swift`**
   - Contact picker with search functionality
   - Permission handling for Contacts access
   - Contact information display

2. **`Roam/Roam/Scenes/Friends/FriendRequestsView.swift`**
   - Friend request management UI
   - Accept/decline actions
   - Time-based request display

### Modified Files

1. **`Roam/Roam/Info.plist`**
   - Added `NSContactsUsageDescription` for contacts access

2. **`Roam/Roam/Services/Models.swift`**
   - Added `Friend` model
   - Added `FriendRequest` model
   - Updated `User` model to include email

3. **`Roam/Roam/Services/APIService.swift`**
   - `fetchFriends()` - Get user's friend list
   - `sendFriendRequest(email:)` - Send friend request by email
   - `acceptFriendRequest(friendshipId:)` - Accept a friend request
   - `removeFriend(friendId:)` - Remove a friend
   - `toggleFriendVisibility(friendId:isVisible:)` - Show/hide friend's vacations
   - `fetchAllVacationsWithFriends()` - Get all vacations (user + visible friends)

4. **`Roam/Roam/Scenes/Friends/AddFriendView.swift`**
   - Complete redesign with contact picker integration
   - Email validation and friend request sending
   - SMS/Email invitation for non-users
   - Error handling and success messages

5. **`Roam/Roam/Scenes/Friends/FriendsListView.swift`**
   - Real API integration (replaces mock data)
   - Swipe to delete friends
   - Toggle visibility for each friend
   - Friend requests button in toolbar
   - Pull to refresh

6. **`Roam/Roam/Scenes/Friends/FriendProfileView.swift`**
   - Updated to work with `Friend` model
   - Fetch and display friend's vacations from API
   - Loading states and error handling

7. **`Roam/Roam/Scenes/Home/HomeView.swift`**
   - Display friends' vacation pins alongside user's own
   - Color-coded pins based on user/friend profile colors
   - Fetch vacations from API with friends' data
   - Pull to refresh all vacations
   - Fallback to mock data if API fails

## Usage Instructions

### Adding Friends

#### Method 1: Add by Email
1. Open the **Friends** tab
2. Tap the **+** button (top right)
3. Enter friend's email address
4. Tap **Send Friend Request**
5. Friend will receive the request and can accept/decline

#### Method 2: Add from Contacts
1. Open the **Friends** tab
2. Tap the **+** button (top right)
3. Tap **Add from Contacts**
4. Grant Contacts permission if prompted
5. Search and select a contact
6. If contact has Roam: Friend request is sent
7. If contact doesn't have Roam: Choose SMS or Email invitation

### Managing Friends

#### View Friend Profile
- Tap on any friend in the Friends list
- See their vacation count, locations, and profile info
- View their vacation details

#### Toggle Friend Visibility
- Use the toggle switch next to each friend's name
- When enabled: Friend's vacation pins appear on globe
- When disabled: Friend's pins are hidden

#### Remove Friend
- Swipe left on a friend's name
- Tap **Remove**
- Friend is removed and their pins disappear from globe

### Friend Requests

#### View Pending Requests
- Tap the **tray icon** (top left in Friends tab)
- See all pending friend requests

#### Accept Request
- Tap **Accept** on any request
- Friend is added to your friends list
- Their vacation pins appear on globe (if visible)

#### Decline Request
- Tap **Decline** on any request
- Request is removed without adding friend

### Globe Visualization

- **Your pins**: Your profile color
- **Friends' pins**: Their individual profile colors
- **Tap any pin**: View vacation details
- **Pull down to refresh**: Update all vacations

## Backend Integration

The iOS app connects to these backend endpoints:

### Friend Endpoints
- `GET /api/friends` - Get friends list
- `POST /api/friends/add` - Send friend request
- `POST /api/friends/accept/:id` - Accept friend request
- `DELETE /api/friends/:id` - Remove friend
- `POST /api/friends/:id/toggle-visibility` - Toggle visibility
- `GET /api/friends/:id/vacations` - Get friend's vacations

### Vacation Endpoints
- `GET /api/vacations` - Get user's vacations
- Friend vacations are fetched via the friends endpoint

## Data Models

### Friend
```swift
struct Friend: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let email: String?
    let color: String
    let profileImage: String?
    let vacationCount: Int
    let locationCount: Int
    let isVisible: Bool
}
```

### FriendRequest
```swift
struct FriendRequest: Identifiable, Codable {
    let id: UUID
    let friendId: UUID
    let friendName: String
    let friendColor: String
    let friendProfileImage: String?
    let status: String // "pending", "accepted", "rejected"
    let createdAt: Date
}
```

### ContactInfo
```swift
struct ContactInfo: Identifiable {
    let id: String
    let name: String
    let email: String?
    let phoneNumber: String?
}
```

## Permissions Required

### iOS Permissions
1. **Contacts Access** (`NSContactsUsageDescription`)
   - Required to import contacts for friend invitations
   - Permission requested when user taps "Add from Contacts"

2. **Photos Access** (`NSPhotoLibraryUsageDescription`)
   - Already implemented for vacation photo uploads

3. **Location Access** (`NSLocationWhenInUseUsageDescription`)
   - Already implemented for globe navigation

## Error Handling

### Contact Access Denied
- Shows informative message directing user to Settings
- Gracefully handles permission denial

### Friend Not Found
- When adding by email: Shows error message
- When adding from contacts: Offers invitation options

### API Failures
- Falls back to mock data for globe view
- Shows error messages in friend list
- Retryable with pull-to-refresh

### Network Issues
- Proper error messages displayed
- User can retry operations
- No crashes on connection failures

## Future Enhancements

### Potential Additions
1. **Push Notifications**
   - Notify when friend request received
   - Notify when friend adds new vacation
   - Notify when friend visits new location

2. **Search & Discovery**
   - Search for users by username
   - Discover friends of friends
   - Suggested friends based on common locations

3. **Privacy Settings**
   - Make profile private/public
   - Hide specific vacations from friends
   - Share selected vacations only

4. **Social Features**
   - Comment on friends' vacations
   - Like/react to locations
   - Share vacation recommendations

5. **Group Features**
   - Create friend groups (e.g., "College Friends", "Family")
   - Filter globe by friend groups
   - Shared/collaborative vacations

## Testing Checklist

### Friend Management
- [ ] Add friend by email (existing user)
- [ ] Add friend by email (non-existing user shows error)
- [ ] Add friend from contacts (existing user)
- [ ] Add friend from contacts (non-existing user offers invite)
- [ ] View friends list
- [ ] Toggle friend visibility
- [ ] Remove friend (swipe to delete)
- [ ] View friend profile
- [ ] Pull to refresh friends list

### Invitations
- [ ] Send email invitation
- [ ] Send SMS invitation
- [ ] Email validation works
- [ ] Cannot add self as friend

### Friend Requests
- [ ] View pending requests
- [ ] Accept friend request
- [ ] Decline friend request
- [ ] Empty state when no requests

### Globe Integration
- [ ] Friends' pins appear on globe
- [ ] Different colors for different friends
- [ ] Toggle visibility hides/shows pins
- [ ] Tap friend's pin shows vacation details
- [ ] Pull to refresh updates vacations
- [ ] Falls back to mock data if API fails

### Permissions
- [ ] Contacts permission requested correctly
- [ ] Permission denial handled gracefully
- [ ] Can re-request permission from Settings

## Architecture Notes

### API Communication
- All API calls use `APIService.shared`
- Proper error handling with `APIError` enum
- Bearer token authentication for all protected endpoints
- Decodable responses for type safety

### State Management
- SwiftUI `@State` for local view state
- `@StateObject` for shared managers (e.g., `LocationManager`)
- No external state management library (pure SwiftUI)

### Navigation
- NavigationStack for iOS 16+ compatibility
- Sheet presentations for modals
- Proper dismiss handling

### Performance
- Lazy loading of friend vacations
- Efficient map rendering with SwiftUI MapKit
- Batch API calls where possible
- Error recovery without full reloads

## Summary

The friends feature is now fully integrated into the Roam app, providing:
- ✅ Easy friend discovery via contacts
- ✅ Seamless invitation flow
- ✅ Rich friend management
- ✅ Social globe experience
- ✅ Privacy controls (visibility toggles)
- ✅ Robust error handling
- ✅ Great UX with proper loading/empty states

Users can now share their travel experiences with friends and discover new destinations through their friends' adventures!

