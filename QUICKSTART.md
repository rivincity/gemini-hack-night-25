# Quick Start Guide - Roam App

## Prerequisites

- macOS with Xcode 14.0 or later
- iOS 14.0+ device or simulator
- Basic knowledge of Swift and UIKit

## Running the App

### 1. Open the Project
```bash
cd Roam
open Roam.xcodeproj
```

### 2. Select Target
- In Xcode, select a simulator (iPhone 14 Pro recommended) or your physical device
- Ensure "Roam" scheme is selected

### 3. Build and Run
- Press `⌘R` or click the Play button
- Wait for the build to complete
- The app will launch on your selected device

## First Launch Experience

### Main Screen (Globe View)
You'll see an interactive world map with three colored pins:
- 🔴 Red pin (Paris/Rome) - Your vacation
- 🔵 Teal pin (Tokyo) - Sarah's vacation  
- 🟢 Mint pin (Machu Picchu) - Mike's vacation

### Try These Actions

1. **Explore Pins**
   - Tap any pin to see vacation details
   - View AI-generated itineraries
   - Click "Book Flights" to open Google Flights
   - Browse recommended articles

2. **Manage Friends**
   - Tap the friends icon (top-right)
   - Toggle visibility switches to show/hide friends' pins
   - Tap a friend to view their profile
   - See their vacation history

3. **Add Vacation (Coming Soon)**
   - Tap the blue + button (bottom-right)
   - See placeholder for photo upload feature

## Project Structure

```
Roam/
├── Models.swift                    # Data models
├── ViewController.swift            # Main entry point
├── GlobeViewController.swift       # Map view
├── PinDetailViewController.swift   # Pin details
├── FriendsViewController.swift     # Friends management
├── AppDelegate.swift              # App lifecycle
└── SceneDelegate.swift            # Scene management
```

## Key Files to Explore

### Models.swift
Contains all data structures:
- `User`: User profiles with colors
- `Vacation`: Trip information
- `VacationLocation`: Individual destinations
- `Photo`, `Activity`, `Article`: Supporting models
- Mock data for testing

### GlobeViewController.swift
Main map interface:
- MapKit integration
- Custom pin annotations
- Friends and add vacation buttons
- Pin selection handling

### PinDetailViewController.swift
Detailed vacation view:
- Scrollable content
- Action buttons (photos, flights)
- Itinerary display
- Article recommendations

### FriendsViewController.swift
Social features:
- Friends list with toggles
- User profiles
- Vacation history

## Customizing Mock Data

Edit `Models.swift` to add your own test data:

```swift
extension User {
    static var mockUsers: [User] {
        [
            User(
                name: "Your Name",
                color: "#FF6B6B",  // Hex color
                vacations: [
                    Vacation(
                        title: "Trip Name",
                        startDate: Date(),
                        endDate: Date(),
                        locations: [
                            VacationLocation(
                                name: "City, Country",
                                coordinate: Coordinate(
                                    latitude: 0.0,
                                    longitude: 0.0
                                ),
                                visitDate: Date(),
                                activities: [...]
                            )
                        ]
                    )
                ]
            )
        ]
    }
}
```

## Common Issues & Solutions

### Issue: Map not loading
**Solution**: Ensure you have an internet connection for map tiles

### Issue: Pins not appearing
**Solution**: Check that mock data has valid coordinates

### Issue: Build errors
**Solution**: Clean build folder (`⌘⇧K`) and rebuild

### Issue: Safari not opening
**Solution**: Ensure you're running on a device/simulator with Safari

## Next Steps

### For Development
1. Implement photo picker for vacation uploads
2. Add EXIF metadata extraction
3. Integrate Gemini API for AI itineraries
4. Build backend for user authentication
5. Add real-time friend features

### For Testing
1. Test on different device sizes
2. Verify all navigation flows
3. Check external link handling
4. Test friend visibility toggles
5. Validate date formatting

## Debugging Tips

### Enable Debug Logging
Add to `AppDelegate.swift`:
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions...) {
    #if DEBUG
    print("🚀 App launched in DEBUG mode")
    #endif
    return true
}
```

### View Hierarchy Debugging
- Run app and pause execution
- Click Debug View Hierarchy button in Xcode
- Inspect UI element positions

### Breakpoints
Set breakpoints in:
- `GlobeViewController.loadPins()` - Pin loading
- `PinDetailViewController.populateContent()` - Detail view
- `FriendsViewController.didToggleVisibility()` - Friend toggles

## Resources

- [Apple MapKit Documentation](https://developer.apple.com/documentation/mapkit)
- [UIKit Documentation](https://developer.apple.com/documentation/uikit)
- [Swift Language Guide](https://docs.swift.org/swift-book/)

## Getting Help

If you encounter issues:
1. Check the console for error messages
2. Review the FEATURES.md for expected behavior
3. Verify your Xcode and iOS versions
4. Clean and rebuild the project

---

Happy coding! 🎉 Ready to bring vacation memories to life!

