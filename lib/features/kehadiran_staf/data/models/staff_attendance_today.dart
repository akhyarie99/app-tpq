class StaffAttendanceToday {
  StaffAttendanceToday({
    required this.date,
    this.clockIn,
    this.clockOut,
    this.clockInLocation,
    this.clockOutLocation,
  });

  final String date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String? clockInLocation;
  final String? clockOutLocation;

  bool get hasClockedIn => clockIn != null;
  bool get hasClockedOut => clockOut != null;

  factory StaffAttendanceToday.fromJson(Map<String, dynamic> json) => StaffAttendanceToday(
        date: json['date'] as String,
        clockIn: json['clock_in'] != null ? DateTime.parse(json['clock_in'] as String) : null,
        clockOut: json['clock_out'] != null ? DateTime.parse(json['clock_out'] as String) : null,
        clockInLocation: json['clock_in_location'] as String?,
        clockOutLocation: json['clock_out_location'] as String?,
      );
}
