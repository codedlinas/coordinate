# Coordinate

A travel tracking app that automatically records your country visits and tracks how long you stay in each location.

## Features

### 🌍 Automatic Country Detection
- GPS-based location tracking to identify which country you're in
- Automatic visit recording when you enter a new country
- Works with geocoding services (primary + OpenStreetMap fallback)

### 📊 Dashboard (Home Screen)
- **Days Tracked** - Total days since you started tracking
- **Countries Visited** - Count of unique countries you've been to
- **Last 24 Hours** - Recent country visits with duration
- **Current Country Banner** - Shows where you are when tracking is active
- **Pull-to-refresh** - Swipe down to refresh data
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

### 🔄 Background Tracking
- Continues tracking even when app is closed
- Uses Android WorkManager for periodic location checks (15-min minimum)
- Country-change detection only (no raw GPS route recording)
- Privacy-focused: only stores country-level data

### 🩺 Tracking Health Screen
- View current permission status (Always / When In Use / Denied)
- Toggle background tracking on/off
- See last background update time
- Force manual location check
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

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Local Storage**: Hive (with code generation)
- **Location**: Geolocator + Geocoding
- **Background Tasks**: WorkManager
- **UI**: Material Design 3 with custom dark theme

## Project Structure

```
lib/
├── core/
│   └── storage/          # Hive initialization
├── data/
│   ├── models/           # CountryVisit, Trip, AppSettings
│   └── repositories/     # Data access layer
├── services/
│   ├── location_service.dart           # GPS + geocoding
│   ├── background_location_service.dart # Background tracking
│   ├── tracking_service.dart           # Foreground tracking
│   └── export_service.dart             # JSON/CSV export
├── state/
│   ├── providers.dart         # Riverpod providers
│   └── tracking_provider.dart # Tracking state
└── ui/
    ├── screens/          # Home, Timeline, Settings, etc.
    ├── theme/            # Dark theme configuration
    └── widgets/          # Reusable UI components
```

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
3. Run `flutter run` on your device

## Notes

- All timestamps are stored in UTC internally
- Background tracking has OS limitations (see Tracking Health screen)
- Some Android manufacturers may kill background tasks aggressively
- iOS background fetch frequency is controlled by the OS

## License

Private project - All rights reserved
