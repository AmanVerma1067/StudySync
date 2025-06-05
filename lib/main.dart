import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  bool isLoading = false;

  final Map<String, Color> subjectColors = {
    'ADC': Colors.blueAccent,
    'DSP': Colors.purpleAccent,
    'AE': Colors.teal,
    'ML': Colors.orange,
    'UHV': Colors.indigoAccent,
    'IE': Colors.green,
    'FA': Colors.redAccent,
    'Litr': Colors.cyanAccent,
    'Psycho': Colors.brown,
  };

  @override
  void initState() {
    super.initState();
    setCurrentDay();
    loadTimetable();
  }

  void setCurrentDay() {
    final now = DateTime.now();
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final todayIndex = now.weekday - 1;
    currentDay = weekdays[todayIndex == 6 ? 0 : todayIndex];
    _tabController = TabController(
        length: 6, vsync: this, initialIndex: weekdays.indexOf(currentDay));
  }

  Future<void> loadTimetable() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://ttserver-7zps.onrender.com/api/timetable'),
        headers: {
          'x-api-key': '123abc456def789ghi',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        await cacheTimetable(response.body);
        applyTimetable(data);
      } else {
        await loadCachedTimetable();
      }
    } catch (_) {
      await loadCachedTimetable();
    }
    setState(() => isLoading = false);
  }

  void applyTimetable(List<dynamic> apiData) {
    final Map<String, dynamic> batchesMap = {};

    for (var batchData in apiData) {
      final batchName = batchData['batch'] as String;
      final batchTimetable = Map<String, dynamic>.from(batchData);
      batchTimetable.remove('batch');
      batchesMap[batchName] = batchTimetable;
    }

    setState(() {
      timetable = {'batches': batchesMap};
      selectedBatch = batchesMap.keys.isNotEmpty ? batchesMap.keys.first : '';
    });
  }

  Future<void> cacheTimetable(String jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_timetable', jsonData);
  }

  Future<void> loadCachedTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_timetable');
    if (cachedData != null) {
      final data = json.decode(cachedData);
      applyTimetable(List<dynamic>.from(data));
    }
  }

  List<Map<String, dynamic>> getClassesForDay(String day) {
    if (timetable['batches'] == null || selectedBatch.isEmpty) return [];
    final classes = timetable['batches'][selectedBatch]?[day];
    if (classes != null) {
      return List<Map<String, dynamic>>.from(classes);
    } else {
      return [];
    }
  }

  Color getSubjectColor(String subject) {
    final firstSubject = subject.split(',').first.trim();
    final subjectKey = firstSubject.replaceAll(RegExp(r'^[T|L|P]-?'), '');

    for (final key in subjectColors.keys) {
      if (subjectKey.contains(key)) return subjectColors[key]!;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: "Sync Timetable",
                onPressed: loadTimetable,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '📚 Study',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          TextSpan(
                            text: 'Sync',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Timetable • by Aman Verma',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                tooltip: "Toggle Theme",
                onPressed: () {
                  setState(() {
                    isDarkMode = !isDarkMode;
                  });
                  final mode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
                  runApp(MaterialApp(
                    title: 'StudySync',
                    debugShowCheckedModeBanner: false,
                    theme: ThemeData.light(useMaterial3: true),
                    darkTheme: ThemeData.dark(useMaterial3: true),
                    themeMode: mode,
                    home: const TimetableScreen(),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : timetable.isEmpty
          ? const Center(child: Text("No data available. Check internet connection."))
          : Column(
        children: [
          BatchSelector(
            timetable: timetable,
            selectedBatch: selectedBatch,
            onChanged: (value) {
              setState(() => selectedBatch = value);
            },
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
                    final color = getSubjectColor(cls['subject']?.toString() ?? '');

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
                        title: Text(cls['subject']?.toString() ?? 'Unknown'),
                        subtitle: Text(
                          'Time: ${cls['time']}\nRoom: ${cls['room']}\nTeacher: ${cls['teacher']}',
                        ),
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

class BatchSelector extends StatelessWidget {
  final Map<String, dynamic> timetable;
  final String selectedBatch;
  final Function(String) onChanged;

  const BatchSelector({
    super.key,
    required this.timetable,
    required this.selectedBatch,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.6),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedBatch,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: Theme.of(context).iconTheme.color ?? Colors.grey,
                size: 28,
              ),
              dropdownColor: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              items: (timetable['batches']?.keys.toList() ?? [])
                  .map<DropdownMenuItem<String>>((String value) {
                final isSelected = selectedBatch == value;
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => ScaleTransition(
                          scale: animation,
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                        child: isSelected
                            ? Container(
                          key: ValueKey('selected_$value'),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                            : const SizedBox(width: 24),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) onChanged(value);
              },
            ),
          ),
        ),
      ),
    );
  }
}
