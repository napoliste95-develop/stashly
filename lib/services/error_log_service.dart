import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoggedError {
  final DateTime timestamp;
  final String message;

  LoggedError({required this.timestamp, required this.message});

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'message': message,
      };

  factory LoggedError.fromJson(Map<String, dynamic> json) => LoggedError(
        timestamp: DateTime.parse(json['timestamp'] as String),
        message: json['message'] as String,
      );
}

class ErrorLogService extends ChangeNotifier {
  static final ErrorLogService instance = ErrorLogService._();
  ErrorLogService._();

  static const _prefsKey = 'error_log';
  static const _maxEntries = 100;

  List<LoggedError> _errors = [];
  List<LoggedError> get errors => List.unmodifiable(_errors);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    _errors = raw
        .map((e) => LoggedError.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> log(String message) async {
    _errors.insert(0, LoggedError(timestamp: DateTime.now(), message: message));
    if (_errors.length > _maxEntries) {
      _errors = _errors.sublist(0, _maxEntries);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _errors.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> clear() async {
    _errors = [];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
