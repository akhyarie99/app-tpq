import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    _load();
  }

  Future<void> _load() async {
    try {
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
      body: Stack(
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
    );
  }
}
