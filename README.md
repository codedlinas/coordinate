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

### 🔄 Background Tracking (Android)
- Continues tracking even when app is closed
- Uses Android WorkManager for periodic location checks (15-min minimum)
- **Border debounce logic** - Requires 2 consecutive checks with the same new country OR 15 minutes of persistence before committing a country change
- **Background task lock** - Prevents race conditions between concurrent location checks
- **Safe Hive initialization** - Uses path_provider for reliable background isolate database access
- Country-change detection only (no raw GPS route recording)
- Privacy-focused: only stores country-level data

### ⚡ High Reliability Mode (Android)
- Optional foreground service for more consistent background tracking
- Visible notification while active (required by Android)
- Better for users who need reliable tracking despite battery optimizations
- Toggle available in Tracking Health screen

### 📱 iOS Strategy
- **Foreground-focused tracking** - Location checks when app is open or resumed
- App lifecycle integration - Automatic location check when returning to app
- Clear onboarding messaging about iOS background limitations
- Manual check available anytime

### 🩺 Tracking Health Screen
- View current permission status (Always / When In Use / Denied)
- Toggle background tracking on/off
- See last background update time
- Force manual location check
- **Developer Diagnostics** (debug mode):
  - Pending country change status
  - Confirmation count and timing
  - Background task lock status
  - Last geocode coordinates and source
- **Platform-specific warnings**:
  - Android: Battery optimization guidance
  - iOS: Foreground-only tracking explanation
- OS limitations info for Android and iOS

### ⚙️ Settings
- **Location Accuracy** - Battery Saver / Balanced / High Precision
- **Tracking Interval** - 5m / 15m / 30m / 1h / 2h
- **Notifications** - Country change alerts, weekly digest
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
- **Background Tasks**: WorkManager (Android), App Lifecycle (iOS)
- **Foreground Service**: flutter_foreground_task (Android)
- **UI**: Material Design 3 with custom dark theme

## Project Structure

```
lib/
├── core/
│   └── storage/          # Hive initialization
├── data/
│   ├── models/           # CountryVisit, Trip, AppSettings, VisitSyncDto
│   └── repositories/     # Data access layer
├── services/
│   ├── location_service.dart              # GPS + geocoding
│   ├── background_location_service.dart   # Background tracking with debounce & lock
│   ├── foreground_location_service.dart   # Android foreground service
│   ├── tracking_service.dart              # Foreground tracking
│   ├── time_ticker_service.dart           # Periodic UI refresh for time-based displays
│   └── export_service.dart                # JSON/CSV export
├── state/
│   ├── providers.dart         # Riverpod providers
│   └── tracking_provider.dart # Tracking state
└── ui/
    ├── screens/          # Home, Timeline, Settings, TrackingHealth, etc.
    ├── theme/            # Dark theme configuration
    └── widgets/          # Reusable UI components
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

### Platform-Specific Strategies
- **Android**: WorkManager periodic tasks + optional foreground service
- **iOS**: Foreground-focused with app lifecycle hooks (background fetch is unreliable on iOS)

### Time-Based UI Auto-Refresh
Time-relative displays like "Last 24 Hours" need to update as time passes, even without new data:
- A `TimeTickerService` emits every 60 seconds while the app is open
- The `timeTickerProvider` (Riverpod StreamProvider) triggers UI rebuilds
- Dashboard watches this provider to automatically recompute time-based filters
- Battery-friendly: only runs when app is in foreground, 60-second interval

## Requirements

- Flutter SDK ^3.8.1
- Android: compileSdk 36, minSdk as per Flutter defaults
- iOS: Deployment target as per Flutter defaults

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
- Location Always (for background tracking)
- Background Modes: location, fetch
- Motion Usage (for battery optimization)

## Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter pub run build_runner build` (for Hive code generation)
4. Run `flutter run` on your device

## Build Notes

### Windows Development
If your project is on a different drive (e.g., D:) than your Pub cache (C:), you may encounter Kotlin incremental compilation issues. This is mitigated by:
```properties
# android/gradle.properties
kotlin.incremental=false
```

## Notes

- All timestamps are stored in UTC internally
- Background tracking has OS limitations (see Tracking Health screen)
- Some Android manufacturers may kill background tasks aggressively
- iOS background fetch frequency is controlled by the OS and is unreliable
- High Reliability Mode uses more battery but provides consistent tracking

## Future: Supabase Sync

The data model is prepared for cloud synchronization:
- `syncId` - Unique identifier for sync
- `updatedAt` - Last modification timestamp
- `deviceId` - Device identifier for multi-device sync
- `isManualEdit` - Flag for conflict resolution (manual edits win)
- `VisitSyncDto` - Privacy-focused DTO excluding GPS coordinates

## License

Private project - All rights reserved
