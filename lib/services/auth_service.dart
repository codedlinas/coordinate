import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/config/supabase_config.dart';

/// Authentication service wrapping Supabase Auth.
/// 
/// Provides email/password and Google Sign-In authentication.
/// Authentication is optional - the app works fully offline without login.
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();
  
  /// The Supabase client instance
  SupabaseClient get _client => Supabase.instance.client;
  
  /// Current authenticated user (null if not logged in)
  User? get currentUser => _client.auth.currentUser;
  
  /// Whether the user is currently authenticated
  bool get isAuthenticated => currentUser != null;
  
  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  
  /// Get a unique device identifier for sync purposes
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return info.identifierForVendor ?? 'ios-unknown';
    } else if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return info.id;
    } else {
      return 'unknown-platform';
    }
  }
  
  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('AuthService: Email sign-in successful for ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('AuthService: Email sign-in failed: $e');
      rethrow;
    }
  }
  
  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      debugPrint('AuthService: Email sign-up successful for ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('AuthService: Email sign-up failed: $e');
      rethrow;
    }
  }
  
  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? SupabaseConfig.googleIosClientId : null,
        serverClientId: SupabaseConfig.googleWebClientId,
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      
      if (idToken == null) {
        throw Exception('No ID token received from Google');
      }
      
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      debugPrint('AuthService: Google sign-in successful for ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('AuthService: Google sign-in failed: $e');
      rethrow;
    }
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in via Google
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      
      await _client.auth.signOut();
      debugPrint('AuthService: Sign out successful');
    } catch (e) {
      debugPrint('AuthService: Sign out failed: $e');
      rethrow;
    }
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      debugPrint('AuthService: Password reset email sent to $email');
    } catch (e) {
      debugPrint('AuthService: Password reset failed: $e');
      rethrow;
    }
  }
  
  /// Delete the current user's account
  /// Note: This requires a Supabase Edge Function or server-side logic
  Future<void> deleteAccount() async {
    // For now, just sign out - account deletion requires server-side implementation
    await signOut();
    debugPrint('AuthService: Account deletion requested (sign out only for now)');
  }
  
  /// Get a user-friendly error message from Supabase auth errors
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Incorrect email or password';
        case 'Email not confirmed':
          return 'Please verify your email address';
        case 'User already registered':
          return 'An account with this email already exists';
        default:
          return error.message;
      }
    }
    return error.toString();
  }
}

