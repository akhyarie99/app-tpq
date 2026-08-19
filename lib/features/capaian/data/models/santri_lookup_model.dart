class SantriLookupModel {
  SantriLookupModel({
    required this.id,
    required this.name,
    required this.nis,
    this.photo,
    this.classId,
    this.className,
  });

  final String id;
  final String name;
  final String nis;
  final String? photo;
  final String? classId;
  final String? className;

  factory SantriLookupModel.fromJson(Map<String, dynamic> json) => SantriLookupModel(
        id: json['id'] as String,
        name: json['name'] as String,
        nis: json['nis'] as String,
        photo: json['photo'] as String?,
        classId: json['class_id'] as String?,
        className: json['class_name'] as String?,
      );
}
