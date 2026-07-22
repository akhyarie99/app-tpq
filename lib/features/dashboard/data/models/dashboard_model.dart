class DashboardClassSummary {
  DashboardClassSummary({
    required this.id,
    required this.name,
    required this.studentCount,
    required this.attendanceSubmittedToday,
  });

  final String id;
  final String name;
  final int studentCount;
  final bool attendanceSubmittedToday;

  factory DashboardClassSummary.fromJson(Map<String, dynamic> json) => DashboardClassSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        studentCount: json['student_count'] as int,
        attendanceSubmittedToday: json['attendance_submitted_today'] as bool,
      );
}

class DashboardData {
  DashboardData({
    required this.totalClasses,
    required this.totalStudents,
    required this.presentToday,
    required this.classes,
  });

  final int totalClasses;
  final int totalStudents;
  final int presentToday;
  final List<DashboardClassSummary> classes;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>;
    return DashboardData(
      totalClasses: stats['totalClasses'] as int,
      totalStudents: stats['totalStudents'] as int,
      presentToday: stats['presentToday'] as int,
      classes: (json['classes'] as List)
          .map((e) => DashboardClassSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
