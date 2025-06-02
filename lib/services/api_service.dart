import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/timetable_model.dart';

class ApiService {
  static Future<List<TimetableEntry>> fetchTimetable() async {
    final String response = await rootBundle.loadString('assets/timetable.json');
    final List<dynamic> data = json.decode(response);
    return data.map((e) => TimetableEntry.fromJson(e)).toList();
  }
}
