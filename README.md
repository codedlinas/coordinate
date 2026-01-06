# Coordinate

A travel tracking app that automatically records your country visits and tracks how long you stay in each location.

## Features

### 🌍 Automatic Country Detection
- GPS-based location tracking to identify which country you're in
- Automatic visit recording when you enter a new country
- Works with geocoding services (primary + OpenStreetMap fallback)
- **Border flip debounce** - Prevents erroneous country changes near borders by requiring confirmation

### 📊 Dashboard (Home Screen)
- **Days Tracked** - Total days since you started tracking
- **Countries Visited** - Count of unique countries you've been to
- **Last 24 Hours** - Recent country visits with duration (auto-refreshes every 60 seconds)
- **Current Country Banner** - Shows where you are when tracking is active
- **Pull-to-refresh** - Swipe down to refresh data
- **Auto-refresh** - Time-based displays update automatically without manual refresh
- **Compact duration display** - Shows time as "2d 5h" format

### 🎨 10 Color Themes
- **Dynamic theme switching** via palette picker icon in the app bar
- 10 curated color palettes:
  - Midnight Aurora (default dark)
  - Ocean Depths (deep blues)
  - Forest Canopy (nature greens)
  - Sunset Ember (warm oranges)
  - Arctic Frost (cool light theme)
  - Neon Cyberpunk (vibrant pinks/cyans)
  - Desert Dusk (sandy earth tones)
  - Lavender Dreams (soft purples)
  - Monochrome (clean grayscale)
  - Coffee House (warm browns)
- Theme preference persisted across app restarts
- Automatic system UI color adaptation

### ✈️ Trips Timeline
- Chronological list of all your trips (newest first)
- Shows country flag, name, arrival/departure dates, and total days
- **"NOW" badge** on ongoing trips
- **Swipe-to-delete** with confirmation dialog
- Tap any trip to edit dates manually

### ✏️ Manual Trip Editing
- Edit arrival and departure dates via date pickers
- All times stored in UTC internally
- Changes automatically update dashboard statistics

### 🔔 Notifications
- **Country Change Alerts** - "Welcome to Germany! 🇩🇪" with flag emoji when entering a new country
- **Travel Reminders** - Scheduled daily notifications ("Traveling today? ✈️")
- Configurable reminder time via time picker
- Master toggle to enable/disable all notifications
- Individual toggles for each notification type

### 🔄 Background Tracking

#### Android (WorkManager)
- Continues tracking even when app is closed
- Uses Android WorkManager for periodic location checks (15-min minimum)
- **Border debounce logic** - Requires 2 consecutive checks with the same new country OR 15 minutes of persistence before committing a country change
- **Background task lock** - Prevents race conditions between concurrent location checks
- **Safe Hive initialization** - Uses path_provider for reliable background isolate database access
- Country-change detection only (no raw GPS route recording)
- Privacy-focused: only stores country-level data

#### iOS (Significant Location Change)
- **Significant Location Change API** - Detects movement of ~500m even when app is terminated
- Wakes app in background to check for border crossings
- Requires "Always Allow" location permission for best results
- MethodChannel communication between native iOS and Flutter
- Automatic location check when app resumes from background
- Battery-efficient: iOS controls update frequency

### ⚡ High Reliability Mode (Android)
- Optional foreground service for more consistent background tracking
- Visible notification while active (required by Android)
- Better for users who need reliable tracking despite battery optimizations
- Toggle available in Tracking Health screen

### 🩺 Tracking Health Screen
- View current permission status (Always / When In Use / Denied)
- Toggle background tracking on/off
- See last background update time
- Force manual location check
- **iOS Significant Location Change status**
- **Developer Diagnostics** (debug mode):
  - Pending country change status
  - Confirmation count and timing
  - Background task lock status
  - Last geocode coordinates and source
- **Platform-specific guidance**:
  - Android: Battery optimization tips
  - iOS: "Always Allow" permission explanation

### ⚙️ Settings
- **Location Accuracy** - Battery Saver / Balanced / High Precision
- **Tracking Interval** - 5m / 15m / 30m / 1h / 2h
- **Notifications**:
  - Master toggle for all notifications
  - Country change alerts
  - Weekly digest
  - Travel reminders with time picker
- **Data Management** - Export (JSON/CSV), reset settings, clear all data

### 📤 Data Export
- Export all visits to JSON (for backup/import)
- Export to CSV (for spreadsheet apps)
- Share exported files directly

### 🔐 Privacy by Design
- Only country-level data stored (no GPS coordinates in permanent storage)
- Sync-ready model with explicit exclusion of location coordinates
- Manual edit flag for conflict resolution
- Device ID for multi-device sync preparation

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Local Storage**: Hive (with code generation)
- **Location**: Geolocator + Geocoding
- **Background Tasks**: 
  - Android: WorkManager + optional Foreground Service
  - iOS: Significant Location Change (CLLocationManager)
- **Notifications**: flutter_local_notifications + timezone
- **UI**: Material Design 3 with 10 dynamic color themes

## Project Structure

```
lib/
├── core/
│   ├── logging/              # App logging utilities
│   └── storage/              # Hive initialization
├── data/
│   ├── models/               # CountryVisit, Trip, AppSettings, VisitSyncDto
│   └── repositories/         # Data access layer
├── services/
│   ├── location_service.dart              # GPS + geocoding
│   ├── background_location_service.dart   # Background tracking with debounce & lock
│   ├── foreground_location_service.dart   # Android foreground service
│   ├── tracking_service.dart              # Foreground tracking
│   ├── notification_service.dart          # Local notifications (country change, reminders)
│   ├── time_ticker_service.dart           # Periodic UI refresh for time-based displays
│   └── export_service.dart                # JSON/CSV export
├── state/
│   ├── providers.dart         # Riverpod providers
│   ├── tracking_provider.dart # Tracking state
│   └── theme_provider.dart    # Theme/palette state management
└── ui/
    ├── screens/          # Home, Timeline, Settings, TrackingHealth, etc.
    ├── theme/
    │   ├── app_theme.dart       # Theme configuration
    │   └── theme_palette.dart   # 10 color palette definitions
    └── widgets/
        ├── palette_picker.dart  # Theme selector widget
        └── ...                  # Other reusable UI components

ios/
└── Runner/
    └── AppDelegate.swift    # iOS Significant Location Change + MethodChannel
```

## Architecture Decisions

### Border Flip Debounce
Near country borders, GPS and geocoding variance can cause rapid country "flips" (e.g., Italy → Slovenia → Italy within minutes). To prevent junk trips:
- A pending country change must be confirmed by **2 consecutive checks** returning the same new country
- OR the pending country must persist for **15 minutes**
- This dramatically reduces false country changes while maintaining responsiveness

### Background Task Lock
To prevent race conditions when `forceLocationCheck()` and scheduled WorkManager tasks run simultaneously:
- A lightweight lock is acquired before processing
- Lock has a 5-minute timeout to prevent deadlocks
- If lock is held, the task exits early

### Safe Background Isolate Initialization
Background tasks run in separate Dart isolates where Flutter bindings may not be available:
- Uses `path_provider` to get app documents directory
- Initializes Hive with explicit path instead of `Hive.initFlutter()`
- Registers adapters only if not already registered

### Platform-Specific Background Strategies
- **Android**: WorkManager periodic tasks (15-min minimum) + optional foreground service for high reliability
- **iOS**: Significant Location Change API (~500m movement detection) + app lifecycle hooks

### iOS Native Integration
The iOS implementation uses a MethodChannel for communication:
- `AppDelegate.swift` implements `CLLocationManagerDelegate`
- Starts/stops monitoring via Flutter method calls
- Sends location updates to Flutter when significant movement detected
- Handles app launch from location events (wakes terminated app)

### Dynamic Theming
- 10 curated palettes defined in `theme_palette.dart`
- `ThemeProvider` manages state with Hive persistence
- `AppTheme` dynamically applies current palette colors
- System UI (status bar, nav bar) adapts to theme brightness

### Hive Migration Handling
When adding new fields to `AppSettings`:
- The generated adapter (`app_settings.g.dart`) is manually modified
- Null-safe defaults prevent crashes when reading old data
- Migration note in `app_settings.dart` documents the required fix

## Requirements

- Flutter SDK ^3.8.1
- Android: compileSdk 36, minSdk as per Flutter defaults
- iOS: Deployment target 14.0+

## Permissions

### Android
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`
- `WAKE_LOCK`
- `RECEIVE_BOOT_COMPLETED`
- `POST_NOTIFICATIONS`

### iOS
- Location When In Use
- Location Always (for Significant Location Change)
- Background Modes: location, fetch
- Motion Usage (for battery optimization)
- Notification permission (for country change alerts)

## Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Run `dart run build_runner build` (for Hive code generation)
4. For iOS: `cd ios && pod install && cd ..`
5. Run `flutter run` on your device

## Build Notes

### Windows Development
If your project is on a different drive (e.g., D:) than your Pub cache (C:), you may encounter Kotlin incremental compilation issues. This is mitigated by:
```properties
# android/gradle.properties
kotlin.incremental=false
```

### iOS Development
- Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`)
- Select your device and click Run
- For device testing without paid Apple Developer account:
  - Trust the developer certificate on device: Settings → General → VPN & Device Management
  - Certificate expires after 7 days

### Hive Migration Warning
If you regenerate Hive adapters with `build_runner`, you MUST re-apply null-safe fixes in `app_settings.g.dart`:
```dart
travelRemindersEnabled: (fields[7] as bool?) ?? false,
travelReminderHour: (fields[8] as int?) ?? 8,
travelReminderMinute: (fields[9] as int?) ?? 0,
```

## Notes

- All timestamps are stored in UTC internally
- Background tracking has OS limitations (see Tracking Health screen)
- Some Android manufacturers may kill background tasks aggressively
- iOS Significant Location Change requires "Always Allow" permission
- High Reliability Mode (Android) uses more battery but provides consistent tracking
- Theme preference is saved locally and persists across app restarts

## Future: Supabase Sync

The data model is prepared for cloud synchronization:
- `syncId` - Unique identifier for sync
- `updatedAt` - Last modification timestamp
- `deviceId` - Device identifier for multi-device sync
- `isManualEdit` - Flag for conflict resolution (manual edits win)
- `VisitSyncDto` - Privacy-focused DTO excluding GPS coordinates

## Changelog

### v1.1.0 (Current)
- ✨ iOS Significant Location Change for background border detection
- ✨ Country change notifications with flag emoji
- ✨ Travel reminder notifications with scheduling
- ✨ 10 dynamic color themes with palette picker
- 🔧 Hive migration handling for new settings fields
- 🔧 iOS 14+ compatibility fixes

### v1.0.0
- Initial release with core tracking functionality
- Android WorkManager background tracking
- iOS foreground-only tracking
- Border flip debounce logic

## License

Private project - All rights reserved
