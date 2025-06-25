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
    final raw = await rootBundle.loadString('assets/calendar.json');
    return json.decode(raw) as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '📆 Academic Calendar',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Colors.purpleAccent,
              // letterSpacing: 1,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.cyan,
            labelColor: Colors.cyan,
            unselectedLabelColor: Colors.blueAccent,
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
              return Center(child: Text('Error: \${snap.error}'));
            }
            final data = snap.data!;
            return TabBarView(
              children: [
                _buildSemesterView(data['odd_semester'] as Map<String, dynamic>, true),
                _buildSemesterView(data['even_semester'] as Map<String, dynamic>, false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSemesterView(Map<String, dynamic> sem, bool isOdd) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionHeader('Registration', Icons.how_to_reg),
        _buildKeyValueCard(sem['registration'] as Map<String, dynamic>, Colors.blueAccent),

        _sectionHeader('Classes Commencement', Icons.school),
        _buildKeyValueCard(sem['classes_commencement'] as Map<String, dynamic>, Colors.teal),

        _sectionHeader('Examinations', Icons.assignment),
        ..._buildExams((sem['examinations'] as Map<String, dynamic>)),

        _sectionHeader('Holidays', Icons.celebration),
        _buildListCard(
          (sem['holidays'] as List).map((e) => '${e['date']}  •  ${e['name']}').toList(),
          Colors.pinkAccent,
        ),

        _sectionHeader('Events', Icons.event),
        _buildListCard(
          (sem['events'] as List).map((e) => '${e['date']}  •  ${e['name']}').toList(),
          Colors.deepOrangeAccent,
        ),

        _sectionHeader('Breaks', Icons.weekend),
        _buildKeyValueCard(sem['breaks'] as Map<String, dynamic>, Colors.purple),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[500]),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueCard(Map<String, dynamic> map, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: map.entries.map((e) {
            return ListTile(
              dense: true,  // reduces default vertical height
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // tighter spacing
              leading: const Icon(Icons.arrow_right, size: 27),
              title: Text(
                _prettifyKey(e.key),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Text(
                e.value.toString(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
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
        color: Colors.indigo.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: ExpansionTile(
          title: Text(
            examName,
            style: const TextStyle(
              fontSize: 14.5,        // 👈 Reduce this to make key text smaller
              fontWeight: FontWeight.w800,
            ),
            // style: const TextStyle(
            //     fontWeight: FontWeight.bold),
          ),
          children: details.entries.map((d) {
            return ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(
                _prettifyKey(d.key),
                style: const TextStyle(
                  fontSize: 13.5,        // 👈 Reduce this to make key text smaller
                  fontWeight: FontWeight.w500,
                ),
              ),
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

  Widget _buildListCard(List<String> items, Color color) {
    return Card(
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: items.map((line) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  Icon(Icons.event_note, size: 20, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(fontSize: 14.5),
                    ),
                  ),
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
