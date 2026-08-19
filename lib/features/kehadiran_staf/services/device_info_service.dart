import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Nama device manusiawi (mis. "Xiaomi Redmi Note 12") — ditampilkan di
/// layar hasil presensi supaya ustadz bisa mengenali device yang dipakai.
Future<String> deviceDisplayName() async {
  try {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return '${info.manufacturer} ${info.model}';
    } else if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return info.utsname.machine;
    }
  } catch (_) {
    // fall through to generic name below
  }
  return '${Platform.operatingSystem} device';
}
