class HafalanModel {
  HafalanModel({
    required this.surahNumber,
    required this.surahName,
    required this.totalAyah,
    required this.memorizedAyah,
    required this.status,
  });

  final int surahNumber;
  final String surahName;
  final int totalAyah;
  final int memorizedAyah;
  final String status;

  double get progress => totalAyah == 0 ? 0 : memorizedAyah / totalAyah;

  factory HafalanModel.fromJson(Map<String, dynamic> json) => HafalanModel(
        surahNumber: json['surah_number'] as int,
        surahName: json['surah_name'] as String,
        totalAyah: json['total_ayah'] as int,
        memorizedAyah: json['memorized_ayah'] as int,
        status: json['status'] as String,
      );
}
