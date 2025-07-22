import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'calendar_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> timetable = {};
  String selectedBatch = '';
  String currentDay = '';
  late TabController _tabController;
  bool isDarkMode = false;
  bool isLoading = false;
  bool showingTimetable = true; // NEW: To toggle between timetable and calendar

  // final Map<String, Color> subjectColors = {
  //   'ADC': Colors.blueAccent,
  //   'DSP': Colors.purpleAccent,
  //   'AE': Colors.teal,
  //   'ML': Colors.orange,
  //   'UHV': Colors.cyan,
  //   'IE': Colors.green,
  //   'FA': Colors.redAccent,
  //   'Litr': Colors.cyanAccent,
  //   'Psycho': Colors.amber,
  // };
  final Map<String, Color> subjectColors = {
    // HSS-2
    'ED': Colors.lightGreen,        // Entrepreneurship Development
    'PP': Colors.pink[200]!,          // Positive Psychology
    'SOY': Colors.lime,             // Sociology of Youth
    'PED': Colors.brown,            // Planning & Economic Development
    'FM': Colors.redAccent,         // Financial Management
    // 'LALL': Colors.grey,            // Common LALL classes

    // DE-1
    'IDIVP': Colors.teal,    // Introduction to Digital Image and video processing
    'MPMC': Colors.yellow[700]!,  //Microprocessors & microcontrollers

    // SE-1
    'MC': Colors.deepOrange,          // Matrix Computations
    'MS': Colors.teal,                // Materials Science
    'NSE': Colors.green,              // Nuclear Science and Engineering
    'LTA': Colors.red,                // Laser Technology and Applications
    // 'QME': Colors.black,              // Quantum Mechanics for Engineers
    'BNM': Colors.indigo,             // Basic Numerical Methods
    'SITA': Colors.lightBlue,         // Statistical Info Theory with Apps
    'LRI': Colors.amber,              // Logical Reasoning and Inequalities

    // Electronics & Communication
    'EMFT': Colors.blueAccent,              // Electromagnetic Field Theory
    'PSPC': Colors.indigo,              // Py for signal processing and communication
    'ESL': Colors.lightBlue,       // Embedded Systems Lab
    'AI': Colors.deepPurple,       // Comprehensive AI
    'DSA': Colors.lime,      // Data Structures and Algorithms
    'MP1': Colors.purpleAccent,         // Minor Project-1
    'ICTK': Colors.green,  //Indian Constitution and traditional knowledge

  };

  @override
  void initState() {
    super.initState();
    setCurrentDay();
    loadTimetable();
  }

  // NEW: Toggle between timetable and calendar
  void _toggleView() {
    setState(() {
      showingTimetable = !showingTimetable;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          showingTimetable
            ? 'Switched to Timetable'
            : 'Switched to Academic Calendar',
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void setCurrentDay() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final todayIndex = now.weekday - 1;
    currentDay = weekdays[todayIndex == 6 ? 0 : todayIndex];
    _tabController = TabController(
        length: 6, vsync: this, initialIndex: weekdays.indexOf(currentDay));
  }

  String _formatTime(String time) {
    try {
      final cleanedTime = time.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = cleanedTime.split(':');
      if (parts.length != 2) return time;

      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = (hour >= 8 && hour < 12) ? 'AM' : 'PM';
      final displayHour = hour > 12 ? hour - 12 : hour;
      return '$displayHour $period';
    } catch (e) {
      return time;
    }
  }

  // // To load local tt for testing
  // Future<void> loadLocalTimetable() async {
  //   try {
  //     final jsonStr = await rootBundle.loadString('assets/timetable.json');
  //     final List<dynamic> data = json.decode(jsonStr);
  //     await cacheTimetable(jsonStr); // So future runs can use this
  //     applyTimetable(data);
  //   } catch (e) {
  //     debugPrint("Failed to load local timetable: $e");
  //   }
  // }

  Future<void> loadTimetable() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://timetable-api-9xsz.onrender.com/api/timetable'),
        headers: {
          'x-api-key': 'tt_api_key',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        await cacheTimetable(response.body);
        applyTimetable(data);

        // NEW: Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable updated successfully!'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        await loadCachedTimetable();

        // NEW: Show offline snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using cached timetable'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {
      await loadCachedTimetable();

      // NEW: Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect. Using cached data'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    // await loadLocalTimetable(); // 👈 fallback for now
    setState(() => isLoading = false);
  }

  // void applyTimetable(List<dynamic> apiData) {
  //   final Map<String, dynamic> batchesMap = {};
  //
  //   for (var batchData in apiData) {
  //     final batchName = batchData['batch'] as String;
  //     final batchTimetable = Map<String, dynamic>.from(batchData);
  //     batchTimetable.remove('batch');
  //     batchesMap[batchName] = batchTimetable;
  //   }
  //
  //   setState(() {
  //     timetable = {'batches': batchesMap};
  //     selectedBatch = batchesMap.keys.isNotEmpty ? batchesMap.keys.first : '';
  //   });
  // }

  void applyTimetable(List<dynamic> apiData) {
    final Map<String, dynamic> batchesMap = {};

    // Check if there's at least one element
    if (apiData.isNotEmpty) {
      // Get the first (and only) element which contains batch objects
      final batchesContainer = apiData[0] as Map<String, dynamic>;

      batchesContainer.forEach((key, batchData) {
        final batchName = batchData['batch'] as String?;
        if (batchName != null) {
          // Create a copy of the batch data without the 'batch' key
          final batchTimetable = Map<String, dynamic>.from(batchData);
          batchTimetable.remove('batch');
          batchesMap[batchName] = batchTimetable;
        }
      });
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.sync),
          tooltip: "Sync Timetable",
          onPressed: loadTimetable,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '📚 Study',
                  style: TextStyle(
                    fontSize: 25,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'Sync',
                  style: TextStyle(
                    fontSize: 25,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '✨ Made by Aman Verma 💫',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: Colors.green[400],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Text(
              showingTimetable ? '📅' : '⏰',
              style: const TextStyle(fontSize: 24),
            ),
            tooltip: showingTimetable ? 'Show Calendar' : 'Show Timetable',
            onPressed: _toggleView,
          ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: "Toggle Theme",
            onPressed: () {
              setState(() => isDarkMode = !isDarkMode);
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
      body: showingTimetable
          ? _buildTimetableBody(days)
          : const CalendarScreen(), // Calendar placeholder
    );
  }
// NEW: Extracted timetable body
  Widget _buildTimetableBody(List<String> days) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : timetable.isEmpty
        ? const Center(
        child: Text("No data available. Check internet connection."))
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
              return LiquidPullToRefresh(
                onRefresh: loadTimetable,
                color: Colors.deepPurpleAccent,
                height: 120,
                backgroundColor: Colors.white,
                animSpeedFactor: 1.2,
                showChildOpacityTransition: false,
                springAnimationDurationInMilliseconds: 700,

                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    final color = getSubjectColor(cls['subject']?.toString() ?? '');

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: color.withOpacity(0.55), width: 1.3),
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.55), color.withOpacity(0.15)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.85),
                          radius: 40,
                          child: Text(
                            _formatTime(cls['time']?.split('-').first.trim() ?? '?'),
                            style: TextStyle(
                              color: Colors.yellow[200],
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          cls['subject']?.toString() ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.blue[500],
                            fontSize: 17,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            '🕒 ${cls['time']}\n📍 Room ${cls['room']}\n👨‍🏫 ${cls['teacher']}',
                            style: TextStyle(
                              height: 1.2,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        isThreeLine: true, // ✅ Now at the correct place
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
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