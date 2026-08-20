// ignore_for_file: avoid_print
//
// Splash screen Android 12+ (API 31+) pakai API baru yang cuma menampilkan
// ikon di dalam "safe zone" lingkaran terbatas — kalau gambar splash-nya
// full-bleed (mengisi penuh kanvas), bagian tepinya KEPOTONG oleh mask itu.
//
// Skrip ini otomatis bikin versi "aman" itu: logo diperkecil ke ~55% kanvas
// dan ditaruh di tengah kanvas putih — jadi selalu ada ruang kosong di
// sekeliling logo, tidak peduli bentuk aslinya.
//
// Pemakaian:
//   dart run tool/generate_splash_safe.dart <flavor_id> <path/logo.png>

import 'dart:io';

import 'package:image/image.dart' as img;

const _canvasSize = 1024;
const _contentRatio = 0.55; // logo mengisi ~55% kanvas, sisanya padding aman

void main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Pemakaian: dart run tool/generate_splash_safe.dart <flavor_id> <path/logo.png>');
    exit(1);
  }

  generateSplashSafe(args[0].trim(), args[1].trim());
}

void generateSplashSafe(String flavorId, String logoPath) {
  final logoFile = File(logoPath);
  if (!logoFile.existsSync()) {
    stderr.writeln('Logo tidak ditemukan: $logoPath');
    exit(1);
  }

  final source = img.decodeImage(logoFile.readAsBytesSync());
  if (source == null) {
    stderr.writeln('Gagal decode gambar: $logoPath');
    exit(1);
  }

  final canvas = img.Image(width: _canvasSize, height: _canvasSize, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));

  final contentSize = (_canvasSize * _contentRatio).round();
  final scale = contentSize / (source.width > source.height ? source.width : source.height);
  final targetWidth = (source.width * scale).round();
  final targetHeight = (source.height * scale).round();

  final resized = img.copyResize(source, width: targetWidth, height: targetHeight, interpolation: img.Interpolation.average);

  img.compositeImage(
    canvas,
    resized,
    dstX: (_canvasSize - targetWidth) ~/ 2,
    dstY: (_canvasSize - targetHeight) ~/ 2,
  );

  final outDir = Directory('assets/flavors/$flavorId');
  outDir.createSync(recursive: true);
  final outPath = '${outDir.path}/splash_safe.png';
  File(outPath).writeAsBytesSync(img.encodePng(canvas));

  print('[ok] Splash safe-zone dibuat untuk flavor "$flavorId" di $outPath');
}
