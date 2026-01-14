// lib/data/services/presence_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking user online/offline status using Firebase Realtime Database
class PresenceService {
  final DatabaseReference _database;
  final FirebaseAuth _auth;

  PresenceService({
    DatabaseReference? database,
    FirebaseAuth? auth,
  })  : _database = database ??
        FirebaseDatabase.instanceFor(
          app: FirebaseDatabase.instance.app,
          databaseURL:
              'https://tutor-finder-0468-default-rtdb.asia-southeast1.firebasedatabase.app',
        ).ref(),
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Setup presence for current user
  /// This creates an onDisconnect handler to automatically set user offline when they disconnect
  Future<void> setupPresence() async {
    if (_currentUserId == null) return;

    try {
      final presenceRef = _database.child('presence/$_currentUserId');
      
      // Set user as online
      await presenceRef.set({
        'online': true,
        'lastSeen': ServerValue.timestamp,
      });

      // Setup onDisconnect handler
      await presenceRef.onDisconnect().set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });

      if (kDebugMode) {
        print('✅ PresenceService: User presence setup complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ PresenceService: Error setting up presence: $e');
      }
    }
  }

  /// Remove presence for current user
  Future<void> removePresence() async {
    if (_currentUserId == null) return;

    try {
      final presenceRef = _database.child('presence/$_currentUserId');
      await presenceRef.set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ PresenceService: Error removing presence: $e');
      }
    }
  }

  /// Get online status stream for a specific user
  Stream<bool> getOnlineStatusStream(String userId) {
    final presenceRef = _database.child('presence/$userId/online');

    return presenceRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return false;
      
      if (value is bool) {
        return value;
      }
      
      // Handle case where value might be stored as string or number
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      
      return false;
    }).handleError((error) {
      if (kDebugMode) {
        print('❌ PresenceService: Error listening to online status: $error');
      }
      return false;
    });
  }

  /// Get online status for a specific user (one-time check)
  Future<bool> isUserOnline(String userId) async {
    try {
      final presenceRef = _database.child('presence/$userId/online');
      final snapshot = await presenceRef.once();
      
      final value = snapshot.snapshot.value;
      if (value == null) return false;
      
      if (value is bool) {
        return value;
      }
      
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PresenceService: Error checking online status: $e');
      }
      return false;
    }
  }
}
