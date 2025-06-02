import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/timetable_model.dart';
import '../services/api_service.dart';
import '../utils/local_storage.dart';
import '../widgets/timetable_card.dart';

class TimetableScreen extends StatefulWidget {
  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<TimetableEntry> _entries = [];
  String _selectedDay = DateFormat('EEEE').format(DateTime.now());
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    try {
      List<TimetableEntry> cached = await LocalStorage.loadTimetable();
      if (cached.isNotEmpty) {
        setState(() => _entries = cached);
      } else {
        List<TimetableEntry> fetched = await ApiService.fetchTimetable();
        setState(() => _entries = fetched);
        await LocalStorage.saveTimetable(fetched);
      }
    } catch (e) {
      print('Error loading timetable: $e');
    }
  }

  void _syncWithOnline() async {
    List<TimetableEntry> fetched = await ApiService.fetchTimetable();
    setState(() => _entries = fetched);
    await LocalStorage.saveTimetable(fetched);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Synced with online data")));
  }

  @override
  Widget build(BuildContext context) {
    final todayEntries = _entries.where((e) => e.day == _selectedDay).toList();

    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text("StudySync Timetable"),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Dropdown for Day Selection
            Padding(
              padding: EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Select Day",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                value: _selectedDay,
                items: [
                  "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
                ]
                    .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDay = value!;
                  });
                },
              ),
            ),

            // Timetable View
            Expanded(
              child: todayEntries.isEmpty
                  ? Center(child: Text("No classes on $_selectedDay"))
                  : ListView.builder(
                itemCount: todayEntries.length,
                itemBuilder: (context, index) =>
                    TimetableCard(entry: todayEntries[index]),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _syncWithOnline,
          label: Text("Sync"),
          icon: Icon(Icons.sync),
        ),
      ),
    );
  }
}
