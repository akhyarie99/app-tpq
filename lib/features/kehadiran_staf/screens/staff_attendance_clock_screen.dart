import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/staff_attendance_provider.dart';
import '../services/device_info_service.dart';
import '../services/face_service.dart';
import '../services/location_service.dart';
import '../widgets/attendance_result_view.dart';
import '../widgets/face_camera_capture.dart';
import 'clock_mode.dart';

enum _Step { location, face, result }

/// Presensi Masuk/Keluar — GPS DAN wajah divalidasi dalam satu aksi berurutan
/// (lokasi diambil dulu, lalu wajah dipindai). Tetap dalam satu screen (bukan
/// push-navigasi ke screen kedua) supaya [_reading] tetap ada di scope yang
/// sama saat wajah dikirim ke server bersama koordinat GPS-nya.
class StaffAttendanceClockScreen extends ConsumerStatefulWidget {
  final ClockMode mode;

  const StaffAttendanceClockScreen({super.key, required this.mode});

  @override
  ConsumerState<StaffAttendanceClockScreen> createState() => _StaffAttendanceClockScreenState();
}

class _StaffAttendanceClockScreenState extends ConsumerState<StaffAttendanceClockScreen> {
  final _locationService = LocationService();
  final _faceService = FaceService();

  _Step _step = _Step.location;

  LocationReading? _reading;
  String? _loadError;
  bool _loadingLocation = true;

  bool? _resultSuccess;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _step = _Step.location;
      _loadingLocation = true;
      _loadError = null;
      _resultMessage = null;
      _resultSuccess = null;
    });
    try {
      final reading = await _locationService.getCurrentReading();
      setState(() => _reading = reading);
    } catch (e) {
      setState(() => _loadError = e.toString());
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  bool get _isMockLocationError => (_resultMessage ?? '').toLowerCase().contains('palsu');

  Future<void> _handleFaceCapture(String imagePath, bool livenessVerified) async {
    final reading = _reading;
    if (reading == null) return;

    final repo = ref.read(staffAttendanceRepositoryProvider);

    try {
      final face = await _faceService.extractEmbedding(imagePath);

      final message = widget.mode == ClockMode.clockIn
          ? await repo.clockIn(reading, face.embedding, face.photoPath, livenessVerified)
          : await repo.clockOut(reading, face.embedding, face.photoPath, livenessVerified);

      if (!mounted) return;
      ref.invalidate(staffAttendanceTodayProvider);
      setState(() {
        _step = _Step.result;
        _resultSuccess = true;
        _resultMessage = message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.result;
        _resultSuccess = false;
        _resultMessage = e.toString();
      });
    }
  }

  List<String> _checklistFor(String message) {
    final lower = message.toLowerCase();
    if (_isMockLocationError) {
      return const ['Matikan aplikasi fake GPS', 'Nonaktifkan "mock location" di Opsi Pengembang'];
    }
    if (lower.contains('belum terdaftar')) {
      return const ['Wajah belum didaftarkan', 'Buka menu "Daftarkan Wajah" terlebih dahulu'];
    }
    if (lower.contains('tidak cocok') || lower.contains('tidak sebanding')) {
      return const ['Pastikan wajah terlihat jelas & pencahayaan cukup', 'Lepas masker/kacamata gelap saat memindai', 'Coba enroll ulang jika masih gagal'];
    }
    if (lower.contains('meter') || lower.contains('lokasi terdekat')) {
      return const ['GPS aktif', 'Anda berada di area masjid/lokasi presensi', 'Jarak Anda masih dalam radius yang diizinkan'];
    }
    return const ['Pastikan pencahayaan cukup', 'Posisikan wajah tepat di dalam bingkai', 'Coba lagi dalam kondisi lebih terang'];
  }

  @override
  Widget build(BuildContext context) {
    final isClockIn = widget.mode == ClockMode.clockIn;

    return Scaffold(
      appBar: AppBar(title: Text(isClockIn ? 'Presensi Masuk' : 'Presensi Keluar')),
      body: _step == _Step.result
          ? _buildResult()
          : _step == _Step.face
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: FaceCameraCapture(
                    instructionText: 'Lihat ke kamera, pastikan wajah terlihat jelas, lalu ambil foto.',
                    onImageCaptured: _handleFaceCapture,
                  ),
                )
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _loadingLocation
                        ? const Center(child: CircularProgressIndicator())
                        : _loadError != null
                            ? _ErrorState(message: _loadError!, onRetry: _loadLocation)
                            : (_reading!.isMockLocation ? _buildMockLocationFailure() : _buildLocationContent()),
                  ),
                ),
    );
  }

  Widget _buildResult() {
    if (_resultSuccess == true) {
      final reading = _reading!;
      return FutureBuilder<String>(
        future: deviceDisplayName(),
        builder: (context, snapshot) {
          return AttendanceResultView.success(
            title: 'Presensi Berhasil!',
            message: _resultMessage ?? 'Selamat, presensi Anda berhasil dicatat.',
            details: [
              MapEntry('Tanggal', DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now())),
              MapEntry('Waktu', DateFormat('HH:mm:ss', 'id_ID').format(DateTime.now())),
              MapEntry('Akurasi GPS', '±${reading.accuracy.toStringAsFixed(1)} m'),
              MapEntry('Perangkat', snapshot.data ?? '-'),
            ],
            onDone: () => Navigator.of(context).pop(true),
          );
        },
      );
    }

    return AttendanceResultView.failure(
      title: _isMockLocationError ? 'Lokasi Palsu Terdeteksi' : 'Presensi Gagal',
      message: _resultMessage ?? 'Presensi gagal, silakan coba lagi.',
      checklist: _checklistFor(_resultMessage ?? ''),
      onRetry: _loadLocation,
      onDone: () => Navigator.of(context).pop(false),
    );
  }

  Widget _buildMockLocationFailure() {
    return AttendanceResultView.failure(
      title: 'Lokasi Palsu Terdeteksi',
      message: 'Lokasi GPS terdeteksi PALSU (mock location).',
      checklist: const [
        'Matikan aplikasi fake GPS',
        'Nonaktifkan "mock location" di Opsi Pengembang',
      ],
      onRetry: _loadLocation,
      onDone: () => Navigator.of(context).pop(false),
    );
  }

  Widget _buildLocationContent() {
    final reading = _reading!;

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Lokasi terverifikasi'),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Latitude: ${reading.lat.toStringAsFixed(6)}'),
                Text('Longitude: ${reading.lng.toStringAsFixed(6)}'),
                Text('Akurasi: ±${reading.accuracy.toStringAsFixed(1)} m'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.face_retouching_natural),
          label: const Text('Lanjutkan ke Verifikasi Wajah'),
          onPressed: () => setState(() => _step = _Step.face),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
