import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/staff_attendance_provider.dart';
import '../services/face_service.dart';
import '../widgets/face_camera_capture.dart';

class FaceEnrollScreen extends ConsumerStatefulWidget {
  const FaceEnrollScreen({super.key});

  @override
  ConsumerState<FaceEnrollScreen> createState() => _FaceEnrollScreenState();
}

class _FaceEnrollScreenState extends ConsumerState<FaceEnrollScreen> {
  final _faceService = FaceService();

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(String imagePath, bool livenessVerified) async {
    try {
      final result = await _faceService.extractEmbedding(imagePath);
      await ref.read(staffAttendanceRepositoryProvider).faceEnroll(result.embedding, result.photoPath);

      if (!mounted) return;
      ref.invalidate(faceEnrollStatusProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wajah berhasil didaftarkan.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftarkan Wajah')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FaceCameraCapture(
          instructionText: 'Posisikan wajah Anda di tengah, pastikan pencahayaan cukup, lalu ambil foto.',
          onImageCaptured: _handleCapture,
        ),
      ),
    );
  }
}
