# Supabase Setup Guide

This document outlines the steps to complete the Supabase integration for the Coordinate app.

## Step 1: Database Setup

Run the SQL commands in `supabase_setup.sql` in your Supabase SQL Editor:
https://supabase.com/dashboard/project/xulkcjygzuqfaotjckht/sql

This will:
- Create the `visits` table
- Enable Row Level Security (RLS)
- Create policies for user data isolation
- Set up automatic `updated_at` timestamp triggers

## Step 2: Get Your Supabase Credentials

1. Go to **Settings > API** in your Supabase dashboard
2. Copy your **Project URL** (e.g., `https://xulkcjygzuqfaotjckht.supabase.co`)
3. Copy your **anon/public key**
4. Update `lib/core/config/supabase_config.dart`:

```dart
static const String url = 'https://xulkcjygzuqfaotjckht.supabase.co';
static const String anonKey = 'YOUR_ANON_KEY_HERE';
```

## Step 3: Enable Authentication Providers

### Email/Password (Already enabled by default)

In Supabase Dashboard:
1. Go to **Authentication > Providers**
2. Ensure **Email** is enabled
3. Optionally configure email templates in **Authentication > Email Templates**

### Google Sign-In

#### 3a. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Go to **APIs & Services > Credentials**
4. Click **Create Credentials > OAuth client ID**
5. Configure OAuth consent screen if prompted

For **Web Client** (required):
- Application type: Web application
- Authorized JavaScript origins: `https://xulkcjygzuqfaotjckht.supabase.co`
- Authorized redirect URIs: `https://xulkcjygzuqfaotjckht.supabase.co/auth/v1/callback`

For **iOS Client**:
- Application type: iOS
- Bundle ID: `com.coordinate.coordinate` (check your actual bundle ID)

For **Android Client**:
- Application type: Android
- Package name: `com.coordinate.coordinate`
- SHA-1 certificate fingerprint: Run `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`

#### 3b. Supabase Configuration

1. Go to **Authentication > Providers > Google**
2. Enable Google provider
3. Add your **Client ID** and **Client Secret** from Google Cloud Console

#### 3c. Update Flutter Config

Update `lib/core/config/supabase_config.dart`:

```dart
static const String googleWebClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
static const String? googleIosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';
```

#### 3d. iOS URL Scheme (for Google Sign-In)

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### Apple Sign-In (Required for iOS App Store)

Apple Sign-In is required if you offer Google Sign-In on iOS. Configure before App Store submission:

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Configure Sign in with Apple capability for your app
3. In Supabase: **Authentication > Providers > Apple**
4. Follow Supabase's Apple Sign-In guide

## Step 4: Install Dependencies

Run:
```bash
flutter pub get
```

## Step 5: Test the Integration

1. Run the app on a device/simulator
2. Go to **Settings > Account**
3. Try signing in with email/password
4. After sign-in, the sync button in the app bar should turn green
5. Tap the sync button to test uploading visits to Supabase

## Troubleshooting

### "Invalid API key" error
- Double-check your `anonKey` in `supabase_config.dart`
- Ensure you're using the anon/public key, not the service_role key

### Google Sign-In not working
- Verify OAuth client IDs match between Google Cloud Console and Flutter config
- Check URL schemes are correctly configured in iOS Info.plist
- For Android, verify SHA-1 fingerprint is registered

### Sync not working
- Ensure RLS policies are correctly applied (check Supabase SQL Editor)
- Verify the user is authenticated (check Profile screen)
- Check network connectivity

## Files Created/Modified

| File | Purpose |
|------|---------|
| `lib/core/config/supabase_config.dart` | Supabase credentials |
| `lib/services/auth_service.dart` | Authentication wrapper |
| `lib/services/sync_service.dart` | Bidirectional sync |
| `lib/ui/screens/auth_screen.dart` | Login/signup UI |
| `lib/ui/screens/profile_screen.dart` | Account management |
| `lib/state/providers.dart` | Auth & sync providers |
| `lib/main.dart` | Supabase initialization |
| `pubspec.yaml` | New dependencies |
| `supabase_setup.sql` | Database schema |

