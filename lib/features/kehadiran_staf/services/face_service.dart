import 'dart:io';
import 'dart:math';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceCaptureResult {
  final List<double> embedding;
  final String photoPath;

  FaceCaptureResult({required this.embedding, required this.photoPath});
}

/// Embedding wajah on-device (MobileFaceNet, input 112x112x3 dinormalisasi ke
/// [-1,1], output embedding 192-d), dicocokkan server-side lewat jarak
/// Euclidean (lihat Api\Mobile\MobileStaffAttendanceController::verifyFace).
///
/// Pencocokan identitas SELALU dilakukan di server — kelas ini cuma
/// mengekstrak angka-angkanya; klien yang dimodifikasi tidak bisa memalsukan
/// hasil "cocok" karena memang tidak ada perbandingan yang bisa dilewati di sisi ini.
class FaceService {
  static const _modelAsset = 'assets/models/mobilefacenet.tflite';
  static const _inputSize = 112;
  static const _minEyeOpenProbability = 0.4;

  Interpreter? _interpreter;
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.2,
    ),
  );

  Future<void> _ensureModelLoaded() async {
    _interpreter ??= await Interpreter.fromAsset(_modelAsset);
  }

  /// Throws [FaceCaptureException] dengan pesan Indonesia yang bisa langsung
  /// ditampilkan ke user (tidak ada wajah, lebih dari satu wajah, mata
  /// tertutup, error model).
  Future<FaceCaptureResult> extractEmbedding(String imagePath) async {
    await _ensureModelLoaded();

    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _detector.processImage(inputImage);

    if (faces.isEmpty) {
      throw FaceCaptureException('Wajah tidak terdeteksi. Pastikan wajah terlihat jelas dan coba lagi.');
    }
    if (faces.length > 1) {
      throw FaceCaptureException('Terdeteksi lebih dari satu wajah. Pastikan hanya wajah Anda yang terlihat.');
    }

    final face = faces.first;

    // Heuristik liveness dasar (bukan anti-spoofing penuh) — pertahanan utama
    // tetap kedipan mata di LivenessStreamService sebelum sampai ke sini.
    final leftOpen = face.leftEyeOpenProbability;
    final rightOpen = face.rightEyeOpenProbability;
    if (leftOpen != null && rightOpen != null &&
        leftOpen < _minEyeOpenProbability && rightOpen < _minEyeOpenProbability) {
      throw FaceCaptureException('Mata terdeteksi tertutup. Lihat ke kamera dan coba lagi.');
    }

    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw FaceCaptureException('Gagal memproses foto. Coba lagi.');
    }

    final cropped = _cropToFace(decoded, face.boundingBox);
    final resized = img.copyResize(cropped, width: _inputSize, height: _inputSize);

    final input = _imageToInputTensor(resized);
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final embeddingLength = outputShape.last;
    final output = [List<double>.filled(embeddingLength, 0)];

    _interpreter!.run(input, output);

    return FaceCaptureResult(embedding: output[0], photoPath: imagePath);
  }

  img.Image _cropToFace(img.Image source, dynamic boundingBox) {
    final rect = boundingBox as dynamic;
    final marginX = rect.width * 0.25;
    final marginY = rect.height * 0.25;

    final left = max(0, (rect.left - marginX).round());
    final top = max(0, (rect.top - marginY).round());
    final right = min(source.width, (rect.right + marginX).round());
    final bottom = min(source.height, (rect.bottom + marginY).round());

    return img.copyCrop(
      source,
      x: left,
      y: top,
      width: max(1, right - left),
      height: max(1, bottom - top),
    );
  }

  /// [1][112][112][3] nested list, tiap channel dinormalisasi ke [-1, 1].
  List<List<List<List<double>>>> _imageToInputTensor(img.Image image) {
    return [
      List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [
            (pixel.r - 127.5) / 127.5,
            (pixel.g - 127.5) / 127.5,
            (pixel.b - 127.5) / 127.5,
          ];
        });
      }),
    ];
  }

  void dispose() {
    _detector.close();
    _interpreter?.close();
  }
}

class FaceCaptureException implements Exception {
  final String message;
  FaceCaptureException(this.message);

  @override
  String toString() => message;
}
