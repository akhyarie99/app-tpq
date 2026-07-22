class SantriModel {
  SantriModel({required this.id, required this.name, this.nis, this.photo});

  final String id;
  final String name;
  final String? nis;
  final String? photo;

  factory SantriModel.fromJson(Map<String, dynamic> json) => SantriModel(
        id: json['id'] as String,
        name: json['name'] as String,
        nis: json['nis'] as String?,
        photo: json['photo'] as String?,
      );
}

/// Status kehadiran per santri saat proses input di layar presensi.
enum KehadiranStatus { hadir, izin, sakit, alfa }

extension KehadiranStatusX on KehadiranStatus {
  String get value => name;

  String get label => switch (this) {
        KehadiranStatus.hadir => 'Hadir',
        KehadiranStatus.izin => 'Izin',
        KehadiranStatus.sakit => 'Sakit',
        KehadiranStatus.alfa => 'Alfa',
      };

  static KehadiranStatus fromValue(String value) =>
      KehadiranStatus.values.firstWhere((e) => e.value == value, orElse: () => KehadiranStatus.hadir);
}
