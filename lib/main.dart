import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const StudySyncApp());
}

class StudySyncApp extends StatelessWidget {
  const StudySyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudySync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const TimetableScreen(),
    );
  }
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic> timetable = {};
  String selectedBatch = '';
  String currentDay = '';
  late TabController _tabController;
  bool isDarkMode = false;

  final Map<String, Color> subjectColors = {
    'ML': Colors.blueAccent,
    'DSP': Colors.purpleAccent,
    'ADC': Colors.teal,
    'AE': Colors.orange,
    'UHV': Colors.indigoAccent,
    'IE': Colors.green,
    'FA': Colors.redAccent,
    'Litr': Colors.cyanAccent,
    'Psycho': Colors.brown,
  };

  @override
  void initState() {
    super.initState();
    loadTimetable();
    setCurrentDay();
  }

  void setCurrentDay() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayIndex = now.weekday - 1;

    setState(() {
      currentDay = weekdays[todayIndex];
      if (currentDay == 'Sunday') currentDay = 'Monday';
      _tabController = TabController(length: 6, vsync: this, initialIndex: weekdays.indexOf(currentDay));
    });
  }

  Future<void> loadTimetable() async {
    final String response = await rootBundle.loadString('assets/timetable.json');
    final data = json.decode(response);
    setState(() {
      timetable = data['batches'];
      selectedBatch = timetable.keys.first;
    });
  }

  List<Map<String, String>> getClassesForDay(String day) {
    final classes = timetable[selectedBatch]?[day];
    if (classes != null) {
      return List<Map<String, String>>.from(
          classes.map((item) => Map<String, String>.from(item))
      );
    } else {
      return [];
    }
  }

  Color getSubjectColor(String subject) {
    for (final key in subjectColors.keys) {
      if (subject.contains(key)) return subjectColors[key]!;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('📘 StudySync - Timetable'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
                final mode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
                // Force rebuild with selected theme mode
                runApp(MaterialApp(
                  title: 'StudySync',
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData.light(useMaterial3: true),
                  darkTheme: ThemeData.dark(useMaterial3: true),
                  themeMode: mode,
                  home: const TimetableScreen(),
                ));
              });
            },
          ),
        ],
      ),
      body: timetable.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).cardColor,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBatch,
                    items: timetable.keys.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBatch = value!;
                      });
                    },
                    isExpanded: true,
                  ),
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: days.map((day) => Tab(text: day)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: days.map((day) {
                final classes = getClassesForDay(day);
                if (classes.isEmpty) {
                  return const Center(child: Text("No classes today!"));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    final color = getSubjectColor(cls['subject'] ?? '');

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.4), width: 1),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Text(cls['time']?.split(':').first ?? '?'),
                        ),
                        title: Text(cls['subject'] ?? 'Unknown'),
                        subtitle: Text('Time: ${cls['time']}\nRoom: ${cls['room']}\nTeacher: ${cls['teacher']}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
