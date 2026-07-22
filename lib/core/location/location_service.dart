import 'package:geolocator/geolocator.dart';

class LocationServiceException implements Exception {
  LocationServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Wrapper geolocator — memastikan izin lokasi diminta dan layanan lokasi aktif
/// sebelum mengambil posisi untuk validasi presensi.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException('Layanan lokasi (GPS) tidak aktif. Aktifkan GPS terlebih dahulu.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException('Izin lokasi ditolak. Aktifkan izin lokasi untuk melakukan presensi.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Izin lokasi ditolak permanen. Aktifkan izin lokasi lewat pengaturan aplikasi.',
      );
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}
