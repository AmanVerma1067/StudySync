class TimetableEntry {
  final String day;
  final String subject;
  final String startTime;
  final String endTime;

  TimetableEntry({
    required this.day,
    required this.subject,
    required this.startTime,
    required this.endTime,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      day: json['day'] ?? '',
      subject: json['subject'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'subject': subject,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
