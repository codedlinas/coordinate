/// Supabase configuration for the Coordinate app.
/// 
/// These values come from your Supabase project dashboard:
/// Settings > API > Project URL and anon/public key
class SupabaseConfig {
  /// Your Supabase project URL
  /// Example: https://xulkcjygzuqfaotjckht.supabase.co
  static const String url = 'https://xulkcjygzuqfaotjckht.supabase.co';
  
  /// Your Supabase anon/public key
  /// Found in Settings > API > Project API keys > anon public
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1bGtjanlnenVxZmFvdGpja2h0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4ODQ4NDgsImV4cCI6MjA4MTQ2MDg0OH0.deCmOevjs0NUpJFzrVZjBpG7E4Kbrsw2kMnaQMEKCHw';
  
  /// Google OAuth Web Client ID (for Google Sign-In)
  /// Get this from Google Cloud Console > APIs & Services > Credentials
  /// TODO: Replace with your actual Google Web Client ID
  static const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';
  
  /// Google OAuth iOS Client ID (for Google Sign-In on iOS)
  /// Get this from Google Cloud Console > APIs & Services > Credentials
  /// TODO: Replace with your actual Google iOS Client ID
  static const String? googleIosClientId = null;
}

