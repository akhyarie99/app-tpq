class KelasModel {
  KelasModel({required this.id, required this.name, required this.studentCount});

  final String id;
  final String name;
  final int studentCount;

  factory KelasModel.fromJson(Map<String, dynamic> json) => KelasModel(
        id: json['id'] as String,
        name: json['name'] as String,
        studentCount: json['student_count'] as int,
      );
}
