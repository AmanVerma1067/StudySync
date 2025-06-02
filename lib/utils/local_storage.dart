import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timetable_model.dart';

class LocalStorage {
  static const String _key = 'timetable';

  static Future<void> saveTimetable(List<TimetableEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<List<TimetableEntry>> loadTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((e) => TimetableEntry.fromJson(e)).toList();
    }
    return [];
  }
}
