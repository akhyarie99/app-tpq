import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Deteksi kedipan mata alami dari stream kamera real-time (BUKAN satu foto
/// statis) — bukti wajah di depan kamera ini "hidup", bukan foto/screenshot
/// yang ditempel. Mata terbuka -> tertutup -> terbuka lagi dalam waktu
/// singkat = kedipan alami.
///
/// [ImageFormatGroup.nv21] di Android supaya plugin kamera sudah mengonversi
/// YUV jadi satu plane NV21 sebelum sampai ke Dart — menghindari konversi
/// manual YUV_420_888 multi-plane yang jauh lebih rawan salah/crash di
/// berbagai HAL kamera OEM.
class LivenessStreamService {
  static const _openThreshold = 0.6;
  static const _closedThreshold = 0.3;
  static const _blinkMaxDuration = Duration(milliseconds: 600);
  static const _minProcessInterval = Duration(milliseconds: 150);
  static const _timeout = Duration(seconds: 12);

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(enableClassification: true, performanceMode: FaceDetectorMode.fast),
  );

  final _statusController = StreamController<LivenessStatus>.broadcast();
  Stream<LivenessStatus> get statusStream => _statusController.stream;

  bool _running = false;
  bool _processing = false;
  DateTime? _lastProcessedAt;
  DateTime? _blinkClosedAt;
  LivenessStatus _status = LivenessStatus.waitingOpen;
  Completer<bool>? _completer;
  Timer? _timeoutTimer;

  /// Mulai memantau stream kamera untuk kedipan alami. Resolve `true` begitu
  /// terverifikasi, `false` kalau timeout tanpa kedipan terdeteksi.
  Future<bool> watch(CameraController controller) async {
    _completer = Completer<bool>();
    _running = true;
    _status = LivenessStatus.waitingOpen;
    _blinkClosedAt = null;
    _statusController.add(_status);

    _timeoutTimer = Timer(_timeout, () => _finish(false));

    await controller.startImageStream((image) => _onFrame(image, controller.description));

    return _completer!.future;
  }

  Future<void> _onFrame(CameraImage image, CameraDescription camera) async {
    if (!_running || _processing) return;

    final now = DateTime.now();
    if (_lastProcessedAt != null && now.difference(_lastProcessedAt!) < _minProcessInterval) return;
    _lastProcessedAt = now;
    _processing = true;

    try {
      final inputImage = _toInputImage(image, camera);
      if (inputImage == null) return;

      final faces = await _detector.processImage(inputImage);
      if (faces.isEmpty) return;

      final face = faces.first;
      final leftOpen = face.leftEyeOpenProbability;
      final rightOpen = face.rightEyeOpenProbability;
      if (leftOpen == null || rightOpen == null) return;

      final eyeOpen = (leftOpen + rightOpen) / 2;
      _evaluate(eyeOpen);
    } finally {
      _processing = false;
    }
  }

  void _evaluate(double eyeOpen) {
    switch (_status) {
      case LivenessStatus.waitingOpen:
        if (eyeOpen > _openThreshold) _setStatus(LivenessStatus.waitingClosed);
      case LivenessStatus.waitingClosed:
        if (eyeOpen < _closedThreshold) {
          _blinkClosedAt = DateTime.now();
          _setStatus(LivenessStatus.blinking);
        }
      case LivenessStatus.blinking:
        final elapsed = DateTime.now().difference(_blinkClosedAt!);
        if (eyeOpen > _openThreshold && elapsed < _blinkMaxDuration) {
          _setStatus(LivenessStatus.verified);
          _finish(true);
        } else if (elapsed >= _blinkMaxDuration) {
          _setStatus(LivenessStatus.waitingOpen);
        }
      case LivenessStatus.verified:
        break;
    }
  }

  void _setStatus(LivenessStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void _finish(bool verified) {
    if (!_running || _completer == null || _completer!.isCompleted) return;
    _running = false;
    _timeoutTimer?.cancel();
    _completer!.complete(verified);
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    if (image.planes.length != 1) return null; // NV21 wajib satu plane — format lain di-skip, bukan di-crash-kan

    const orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    final sensorOrientation = camera.sensorOrientation;
    var rotationCompensation = orientations[DeviceOrientation.portraitUp] ?? 0;
    rotationCompensation = camera.lensDirection == CameraLensDirection.front
        ? (sensorOrientation + rotationCompensation) % 360
        : (sensorOrientation - rotationCompensation + 360) % 360;

    final rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    if (rotation == null) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void cancel() {
    _running = false;
    _timeoutTimer?.cancel();
  }

  void dispose() {
    cancel();
    _statusController.close();
    _detector.close();
  }
}

enum LivenessStatus { waitingOpen, waitingClosed, blinking, verified }
