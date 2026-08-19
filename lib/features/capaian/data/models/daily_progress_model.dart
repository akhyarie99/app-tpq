class DailyProgressModel {
  DailyProgressModel({
    required this.date,
    required this.method,
    required this.keterangan,
    required this.summary,
    this.jilid,
    this.halaman,
    this.surah,
    this.ayatAwal,
    this.ayatAkhir,
    this.catatan,
  });

  final String date;
  final String method;
  final String keterangan;
  final String summary;
  final int? jilid;
  final int? halaman;
  final String? surah;
  final int? ayatAwal;
  final int? ayatAkhir;
  final String? catatan;

  factory DailyProgressModel.fromJson(Map<String, dynamic> json) => DailyProgressModel(
        date: json['date'] as String,
        method: json['method'] as String,
        keterangan: json['keterangan'] as String,
        summary: json['summary'] as String,
        jilid: json['jilid'] as int?,
        halaman: json['halaman'] as int?,
        surah: json['surah'] as String?,
        ayatAwal: json['ayat_awal'] as int?,
        ayatAkhir: json['ayat_akhir'] as int?,
        catatan: json['catatan'] as String?,
      );
}
