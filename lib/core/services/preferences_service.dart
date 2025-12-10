import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing local preferences using SharedPreferences
class PreferencesService {
  static const String _savedTutorsKey = 'saved_tutor_ids';
  static const String _lastSearchQueryKey = 'last_search_query';
  static const String _selectedSubjectKey = 'selected_subject';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  /// Get saved tutor IDs
  Future<List<String>> getSavedTutorIds() async {
    final savedIds = _prefs.getStringList(_savedTutorsKey) ?? [];
    return savedIds;
  }

  /// Save tutor ID
  Future<bool> saveTutorId(String tutorId) async {
    final savedIds = await getSavedTutorIds();
    if (!savedIds.contains(tutorId)) {
      savedIds.add(tutorId);
      return await _prefs.setStringList(_savedTutorsKey, savedIds);
    }
    return true;
  }

  /// Remove tutor ID from saved list
  Future<bool> removeTutorId(String tutorId) async {
    final savedIds = await getSavedTutorIds();
    savedIds.remove(tutorId);
    return await _prefs.setStringList(_savedTutorsKey, savedIds);
  }

  /// Check if tutor is saved
  Future<bool> isTutorSaved(String tutorId) async {
    final savedIds = await getSavedTutorIds();
    return savedIds.contains(tutorId);
  }

  /// Save last search query
  Future<bool> saveLastSearchQuery(String query) async {
    return await _prefs.setString(_lastSearchQueryKey, query);
  }

  /// Get last search query
  String? getLastSearchQuery() {
    return _prefs.getString(_lastSearchQueryKey);
  }

  /// Save selected subject filter
  Future<bool> saveSelectedSubject(String subject) async {
    return await _prefs.setString(_selectedSubjectKey, subject);
  }

  /// Get selected subject filter
  String? getSelectedSubject() {
    return _prefs.getString(_selectedSubjectKey);
  }

  /// Clear all preferences
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}

/// Factory function to create PreferencesService
Future<PreferencesService> createPreferencesService() async {
  final prefs = await SharedPreferences.getInstance();
  return PreferencesService(prefs);
}

