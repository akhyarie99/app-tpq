import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../services/liveness_stream_service.dart';

/// Kamera + capture bersama, dipakai baik untuk enrollment wajah maupun
/// presensi masuk/keluar — bedanya cuma apa yang terjadi setelah foto diambil
/// (lihat [onImageCaptured]).
///
/// Capture otomatis: kedipan mata alami dideteksi pasif dari stream kamera
/// live (lihat LivenessStreamService) sebelum foto diam diambil, jadi foto
/// cetak atau screenshot HP yang ditempel ke kamera tidak bisa berkedip dan
/// tidak akan lolos. Tidak perlu tombol "ambil foto" manual.
class FaceCameraCapture extends StatefulWidget {
  final String instructionText;
  final Future<void> Function(String imagePath, bool livenessVerified) onImageCaptured;

  const FaceCameraCapture({
    super.key,
    required this.instructionText,
    required this.onImageCaptured,
  });

  @override
  State<FaceCameraCapture> createState() => _FaceCameraCaptureState();
}

class _FaceCameraCaptureState extends State<FaceCameraCapture> {
  CameraController? _controller;
  final _liveness = LivenessStreamService();
  String? _error;
  bool _processing = false;
  bool _timedOut = false;
  LivenessStatus _status = LivenessStatus.waitingOpen;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();

      if (!mounted) return;
      setState(() => _controller = controller);
      _startWatching();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal membuka kamera: $e');
    }
  }

  void _startWatching() {
    setState(() {
      _timedOut = false;
      _status = LivenessStatus.waitingOpen;
    });

    final sub = _liveness.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });

    _liveness.watch(_controller!).then((verified) async {
      sub.cancel();
      if (!mounted) return;

      if (!verified) {
        setState(() => _timedOut = true);
        return;
      }

      await _captureAfterVerified();
    });
  }

  Future<void> _captureAfterVerified() async {
    final controller = _controller;
    if (controller == null || _processing) return;

    setState(() => _processing = true);
    try {
      // Stream harus berhenti dulu sebelum takePicture() — beberapa
      // implementasi kamera Android tidak mengizinkan keduanya jalan bersamaan.
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final file = await controller.takePicture();
      await widget.onImageCaptured(file.path, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _retry() {
    if (_controller?.value.isStreamingImages ?? false) return;
    _startWatching();
  }

  @override
  void dispose() {
    _liveness.dispose();
    _controller?.dispose();
    super.dispose();
  }

  String get _statusText {
    if (_processing) return 'Memindai wajah...';
    switch (_status) {
      case LivenessStatus.waitingOpen:
      case LivenessStatus.waitingClosed:
        return 'Lihat ke kamera, tunggu sebentar...';
      case LivenessStatus.blinking:
        return 'Terdeteksi berkedip...';
      case LivenessStatus.verified:
        return 'Terverifikasi! Mengambil foto...';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // SafeArea: Android 15+ (edge-to-edge wajib) menggambar konten sampai ke
    // belakang navigation bar bawaan HP kalau tidak dibungkus ini.
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(controller),
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.65,
                        heightFactor: 0.55,
                        child: CustomPaint(painter: _CornerFramePainter(color: AppColors.primary600)),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: _processing ? AppColors.warning : AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _statusText,
                                style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.instructionText, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            'Verifikasi otomatis — cukup lihat ke kamera dan berkedip seperti biasa.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          if (_timedOut) ...[
            const SizedBox(height: 12),
            Text(
              'Kedipan mata alami tidak terdeteksi. Pastikan wajah Anda terlihat jelas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _retry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Coba Lagi'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bingkai sudut ala pemindai wajah (empat siku di pojok) yang digambar di
/// atas preview kamera — murni dekoratif, memandu posisi wajah pengguna.
class _CornerFramePainter extends CustomPainter {
  final Color color;

  _CornerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;

    void drawCorner(Offset origin, Offset dx, Offset dy) {
      canvas.drawLine(origin, origin + dx, paint);
      canvas.drawLine(origin, origin + dy, paint);
    }

    drawCorner(const Offset(0, 0), const Offset(cornerLength, 0), const Offset(0, cornerLength));
    drawCorner(Offset(size.width, 0), const Offset(-cornerLength, 0), const Offset(0, cornerLength));
    drawCorner(Offset(0, size.height), const Offset(cornerLength, 0), const Offset(0, -cornerLength));
    drawCorner(
      Offset(size.width, size.height),
      const Offset(-cornerLength, 0),
      const Offset(0, -cornerLength),
    );
  }

  @override
  bool shouldRepaint(covariant _CornerFramePainter oldDelegate) => oldDelegate.color != color;
}
