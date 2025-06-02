import 'package:flutter/material.dart';
import '../models/timetable_model.dart';

class TimetableCard extends StatelessWidget {
  final TimetableEntry entry;

  TimetableCard({required this.entry});

  Color _getSubjectColor(String subject) {
    final colors = {
      'Math': Colors.blueAccent,
      'Physics': Colors.orangeAccent,
      'Chemistry': Colors.purpleAccent,
      'English': Colors.greenAccent,
      'Biology': Colors.redAccent,
    };
    return colors[subject] ?? Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getSubjectColor(entry.subject),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          entry.subject,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        subtitle: Text('${entry.day} | ${entry.startTime} - ${entry.endTime}'),
        leading: Icon(Icons.schedule, color: Colors.black),
      ),
    );
  }
}
