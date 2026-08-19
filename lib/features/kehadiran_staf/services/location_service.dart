import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';

class LocationReading {
  final double lat;
  final double lng;
  final double accuracy;
  final bool isMockLocation;
  final Map<String, dynamic> deviceInfo;

  LocationReading({
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.isMockLocation,
    required this.deviceInfo,
  });
}

/// Anti-fake-GPS: cross-check dua sinyal independen sebelum mempercayai
/// bacaan GPS, lalu kumpulkan metadata integritas device untuk audit trail
/// server (lihat staff_attendances.clock_in_device_info).
///
/// Layer 1 — `Position.isMocked` dari geolocator: di Android ini merefleksikan
/// `Location.isFromMockProvider()`, true kalau koordinat berasal dari
/// provider yang terdaftar sebagai mock provider (begitulah sebagian besar
/// app "fake GPS" dari Play Store bekerja).
///
/// Layer 2 — `SafeDevice.isMockLocation`: pengecekan native independen dari
/// package safe_device, sebagai opini kedua kalau satu implementasi
/// terlewat oleh yang lain.
class LocationService {
  Future<LocationReading> getCurrentReading() async {
    await _ensurePermission();

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

    final safeDeviceMock = await _safeCall(() => SafeDevice.isMockLocation, false);
    final isMocked = position.isMocked || safeDeviceMock;

    final deviceInfo = <String, dynamic>{
      'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'other'),
      'is_rooted_or_jailbroken': await _safeCall(() => SafeDevice.isJailBroken, false),
      'is_real_device': await _safeCall(() => SafeDevice.isRealDevice, true),
      'is_mock_location_geolocator': position.isMocked,
      'is_mock_location_safe_device': safeDeviceMock,
    };

    return LocationReading(
      lat: position.latitude,
      lng: position.longitude,
      accuracy: position.accuracy,
      isMockLocation: isMocked,
      deviceInfo: deviceInfo,
    );
  }

  Future<T> _safeCall<T>(Future<T> Function() fn, T fallback) async {
    try {
      return await fn();
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Aktifkan GPS/Location Services terlebih dahulu.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak. Aktifkan izin lokasi di pengaturan aplikasi.');
    }
  }
}
