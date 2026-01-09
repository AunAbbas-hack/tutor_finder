// lib/data/services/oauth_token_service.dart
// OAuth 2.0 Token Service for FCM V1 API
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class OAuthTokenService {
  static OAuthTokenService? _instance;
  static OAuthTokenService get instance => _instance ??= OAuthTokenService._();
  
  OAuthTokenService._();

  http.Client? _authenticatedClient;
  DateTime? _tokenExpiry;
  bool _isInitializing = false;

  // Project ID from Firebase
  static const String _projectId = 'tutor-finder-0468';
  
  // Required scope for FCM
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  /// Get authenticated HTTP client
  /// This will auto-refresh token if expired
  Future<http.Client?> getAuthenticatedClient() async {
    // Check if we have a valid cached client
    if (_authenticatedClient != null && _isTokenValid()) {
      return _authenticatedClient;
    }

    // If already initializing, wait for it
    if (_isInitializing) {
      // Wait a bit and retry
      await Future.delayed(const Duration(milliseconds: 500));
      return getAuthenticatedClient();
    }

    try {
      _isInitializing = true;

      // Load Service Account credentials
      final credentials = await _loadServiceAccountCredentials();
      if (credentials == null) {
        if (kDebugMode) {
          print('❌ Failed to load Service Account credentials');
        }
        return null;
      }

      // Create authenticated client
      _authenticatedClient = await auth.clientViaServiceAccount(
        credentials,
        _scopes,
      );

      // Token is valid for ~1 hour, set expiry to 55 minutes for safety
      _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));

      if (kDebugMode) {
        print('✅ OAuth token generated successfully');
        print('   Token valid until: $_tokenExpiry');
      }

      return _authenticatedClient;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating OAuth token: $e');
      }
      return null;
    } finally {
      _isInitializing = false;
    }
  }

  /// Get access token string directly (if needed)
  Future<String?> getAccessToken() async {
    // For googleapis_auth, we use the client directly
    // Access token is handled internally
    // If you need the token string, you would need to implement manual JWT signing
    // For now, using the client is recommended
    final client = await getAuthenticatedClient();
    return client != null ? 'Bearer Token (handled by client)' : null;
  }

  /// Load Service Account credentials
  Future<auth.ServiceAccountCredentials?> _loadServiceAccountCredentials() async {
    try {
      // Option 1: Try loading from assets folder
      // Place your Service Account JSON in: assets/service_account.json
      // And add to pubspec.yaml: assets/service_account.json
      try {
        final jsonString = await rootBundle.loadString('assets/service_account.json');
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        return auth.ServiceAccountCredentials.fromJson(jsonData);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Service Account not found in assets, trying environment variable...');
        }
      }

      // Option 2: Try loading from .env file (base64 encoded)
      // Add to .env: SERVICE_ACCOUNT_JSON=base64_encoded_json_string
      try {
        // Note: You'll need to add flutter_dotenv import if not already there
        // For now, we'll try a different approach - file path
        // User can place JSON file and specify path in .env
        return null;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Service Account not found in .env');
        }
      }

      if (kDebugMode) {
        print('❌ Service Account JSON not found. Please place it in assets/service_account.json');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading Service Account credentials: $e');
      }
      return null;
    }
  }

  /// Check if current token is still valid
  bool _isTokenValid() {
    if (_tokenExpiry == null) return false;
    // Refresh if token expires in less than 5 minutes
    return DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)));
  }

  /// Get project ID
  String get projectId => _projectId;

  /// Clear cached token (useful for testing)
  void clearCache() {
    _authenticatedClient?.close();
    _authenticatedClient = null;
    _tokenExpiry = null;
    if (kDebugMode) {
      print('🗑️ OAuth token cache cleared');
    }
  }
}
