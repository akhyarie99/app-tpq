import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../core/constants/app_config.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';

/// Membuka halaman web SiMasjid (modul yang belum punya layar native) di dalam
/// app, dengan auto-login lewat pertukaran token webview -> sesi Laravel.
class WebviewScreen extends ConsumerStatefulWidget {
  const WebviewScreen({super.key, required this.path, required this.title});

  /// Path relatif di web app, contoh: "/admin/keuangan/laporan".
  final String path;
  final String title;

  @override
  ConsumerState<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends ConsumerState<WebviewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('SimasjidApp/1.0 Flutter Android')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (error) => setState(() {
            _loading = false;
            _error = 'Gagal memuat halaman: ${error.description}';
          }),
        ),
      );

    // WebView Android tidak bisa membuka file picker sendiri untuk
    // <input type="file"> (mis. upload foto profil/logo) — tanpa ini tombol
    // upload di halaman web terlihat seperti tidak berbuat apa-apa sama
    // sekali (bukan soal izin runtime, callback-nya memang belum ada).
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setOnShowFileSelector(_onShowFileSelector);
    }

    _load();
  }

  Future<List<String>> _onShowFileSelector(FileSelectorParams params) async {
    final source = await _pickImageSource();
    if (source == null) return [];

    final ImagePicker picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return [];
    }
    if (file == null) return [];

    return [Uri.file(file.path).toString()];
  }

  Future<ImageSource?> _pickImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    try {
      // Selalu pakai HTML/JS/CSS terbaru dari server — WebView cenderung menyimpan
      // cache HTTP lebih lama daripada Chrome biasa, yang bisa membuat halaman admin
      // "ketinggalan" versi setelah ada deploy baru.
      await _controller.clearCache();

      final webviewToken = await ref.read(authRepositoryProvider).getWebviewToken();
      final uri = Uri.parse('${AppConfig.webBaseUrl}/webview-login').replace(queryParameters: {
        'token': webviewToken,
        'redirect': widget.path,
      });
      await _controller.loadRequest(uri);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (_error == null) WebViewWidget(controller: _controller),
            if (_error != null) ErrorView(message: _error!, onRetry: () {
              setState(() {
                _error = null;
                _loading = true;
              });
              _load();
            }),
            if (_loading && _error == null) const LoadingView(),
          ],
        ),
      ),
    );
  }
}
