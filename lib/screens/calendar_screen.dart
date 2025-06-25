import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<Map<String, dynamic>> _calendarFuture;

  @override
  void initState() {
    super.initState();
    _calendarFuture = _loadCalendarJson();
  }

  Future<Map<String, dynamic>> _loadCalendarJson() async {
    final raw = await rootBundle.loadString('assets/academic_calendar.json');
    return json.decode(raw) as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Calendar'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Odd Semester'),
            Tab(text: 'Even Semester'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _calendarFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final data = snap.data!;
          return TabBarView(
            children: [
              _buildSemesterView(data['odd_semester'] as Map<String, dynamic>),
              _buildSemesterView(data['even_semester'] as Map<String, dynamic>),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSemesterView(Map<String, dynamic> sem) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionHeader('Registration'),
        _buildKeyValueCard(sem['registration'] as Map<String, dynamic>),
        const SizedBox(height: 12),

        _sectionHeader('Classes Commencement'),
        _buildKeyValueCard(sem['classes_commencement'] as Map<String, dynamic>),
        const SizedBox(height: 12),

        _sectionHeader('Examinations'),
        ..._buildExams((sem['examinations'] as Map<String, dynamic>)),
        const SizedBox(height: 12),

        _sectionHeader('Holidays'),
        _buildListCard(
          (sem['holidays'] as List)
              .map((e) => '${e['date']}  •  ${e['name']}')
              .toList(),
        ),
        const SizedBox(height: 12),

        _sectionHeader('Events'),
        _buildListCard(
          (sem['events'] as List)
              .map((e) => '${e['date']}  •  ${e['name']}')
              .toList(),
        ),
        const SizedBox(height: 12),

        _sectionHeader('Breaks'),
        _buildKeyValueCard(sem['breaks'] as Map<String, dynamic>),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildKeyValueCard(Map<String, dynamic> map) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: map.entries.map((e) {
            return ListTile(
              dense: true,
              title: Text(_prettifyKey(e.key)),
              trailing: Text(
                e.value.toString(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Widget> _buildExams(Map<String, dynamic> exams) {
    return exams.entries.map((examEntry) {
      final examName = examEntry.key.replaceAll('_', ' ').toUpperCase();
      final details = examEntry.value as Map<String, dynamic>;
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        child: ExpansionTile(
          title: Text(examName),
          children: details.entries.map((d) {
            return ListTile(
              title: Text(_prettifyKey(d.key)),
              trailing: Text(
                d.value.toString(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  Widget _buildListCard(List<String> items) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: items.map((line) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(line)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _prettifyKey(String key) {
    return key
        .split(RegExp(r'[_\s]+'))
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
