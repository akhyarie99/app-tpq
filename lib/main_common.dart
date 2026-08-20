import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/flavor_config.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'shared/theme/app_theme.dart';

/// Dipanggil dari tiap main_{flavor}.dart setelah men-set FlavorConfig.instance.
/// Contoh pemakaian di main_tpqalazharcilacap.dart:
///
/// void main() {
///   FlavorConfig.setInstance(tpqalazharcilacapConfig);
///   runSiMasjidApp();
/// }
Future<void> runSiMasjidApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const ProviderScope(child: SiMasjidApp()));
}

class SiMasjidApp extends StatelessWidget {
  const SiMasjidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: FlavorConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('id', 'ID'),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return switch (authState.status) {
      AuthStatus.bootstrapping => const _SplashScreen(),
      AuthStatus.authenticated => const DashboardScreen(),
      AuthStatus.unauthenticated || AuthStatus.authenticating => const LoginScreen(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
