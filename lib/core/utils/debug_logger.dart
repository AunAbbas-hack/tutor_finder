// lib/core/utils/debug_logger.dart
import 'dart:io';
import 'dart:convert';

class DebugLogger {
  static const String logPath = '/Users/work/AndroidStudioProjects/tutor_finder/.cursor/debug.log';

  static Future<void> log({
    required String location,
    required String message,
    Map<String, dynamic>? data,
    String? hypothesisId,
    String sessionId = 'debug-session',
    String runId = 'run1',
  }) async {
    try {
      final logEntry = {
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'location': location,
        'message': message,
        'data': data ?? {},
        'sessionId': sessionId,
        'runId': runId,
        if (hypothesisId != null) 'hypothesisId': hypothesisId,
      };

      final file = File(logPath);
      final jsonLine = jsonEncode(logEntry);
      await file.writeAsString('$jsonLine\n', mode: FileMode.append);
    } catch (e) {
      // Silently fail - don't break the app
    }
  }
}

