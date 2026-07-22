class SubjectModel {
  SubjectModel({required this.id, required this.name});

  final String id;
  final String name;

  factory SubjectModel.fromJson(Map<String, dynamic> json) =>
      SubjectModel(id: json['id'] as String, name: json['name'] as String);
}

class GradeModel {
  GradeModel({
    required this.subjectId,
    required this.subjectName,
    required this.score,
    this.gradeLetter,
    this.description,
  });

  final String subjectId;
  final String? subjectName;
  final num score;
  final String? gradeLetter;
  final String? description;

  factory GradeModel.fromJson(Map<String, dynamic> json) => GradeModel(
        subjectId: json['subject_id'] as String,
        subjectName: json['subject'] as String?,
        score: json['score'] as num,
        gradeLetter: json['grade_letter'] as String?,
        description: json['description'] as String?,
      );
}

class CapaianDetail {
  CapaianDetail({
    required this.studentId,
    required this.studentName,
    this.activeSemesterId,
    this.activeSemesterName,
    required this.subjects,
    required this.grades,
  });

  final String studentId;
  final String studentName;
  final String? activeSemesterId;
  final String? activeSemesterName;
  final List<SubjectModel> subjects;
  final List<GradeModel> grades;

  factory CapaianDetail.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>;
    final semester = json['active_semester'] as Map<String, dynamic>?;

    return CapaianDetail(
      studentId: student['id'] as String,
      studentName: student['name'] as String,
      activeSemesterId: semester?['id'] as String?,
      activeSemesterName: semester?['name'] as String?,
      subjects:
          (json['subjects'] as List).map((e) => SubjectModel.fromJson(e as Map<String, dynamic>)).toList(),
      grades: (json['grades'] as List).map((e) => GradeModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
