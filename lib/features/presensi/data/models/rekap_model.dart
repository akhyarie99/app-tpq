class RekapItem {
  RekapItem({
    required this.studentId,
    required this.studentName,
    this.studentNis,
    required this.presentCount,
    required this.sickCount,
    required this.permissionCount,
    required this.absentCount,
    required this.percent,
  });

  final String studentId;
  final String studentName;
  final String? studentNis;
  final int presentCount;
  final int sickCount;
  final int permissionCount;
  final int absentCount;
  final double percent;

  factory RekapItem.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>;
    return RekapItem(
      studentId: student['id'] as String,
      studentName: student['name'] as String,
      studentNis: student['nis'] as String?,
      presentCount: json['present_count'] as int,
      sickCount: json['sick_count'] as int,
      permissionCount: json['permission_count'] as int,
      absentCount: json['absent_count'] as int,
      percent: (json['percent'] as num).toDouble(),
    );
  }
}
