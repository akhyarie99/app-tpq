import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/screens/beranda_tab.dart';
import '../../kehadiran_staf/screens/kehadiran_tab.dart';
import '../../profile/screens/profil_tab.dart';

/// Shell utama setelah login — bottom navigation dengan 3 tab (Beranda,
/// Kehadiran, Profil). "Menu Lainnya" (web admin lengkap) sengaja TIDAK jadi
/// tab di sini — dibuka lewat Navigator.push dari dalam tab supaya bottom
/// nav bar ini tidak ikut tampil dobel di atas sidebar/menu web-nya sendiri.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferBiometric());
  }

  void _navigateTab(int index) => setState(() => _index = index);

  Future<void> _maybeOfferBiometric() async {
    final auth = ref.read(authProvider.notifier);
    if (!auth.consumeJustLoggedIn()) return;
    if (!ref.read(authProvider).biometricAvailable) return;
    if (await auth.isBiometricEnabled()) return;
    if (!mounted) return;

    final enable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aktifkan Login Biometrik?'),
        content: const Text(
          'Buka aplikasi berikutnya cukup dengan sidik jari/wajah, tanpa perlu ketik kata sandi lagi.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Nanti Saja')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Aktifkan')),
        ],
      ),
    );

    if (enable == true) {
      await auth.setBiometricEnabled(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      BerandaTab(onNavigateTab: _navigateTab),
      const KehadiranTab(),
      const ProfilTab(),
    ];

    // SafeArea: Android 15+ (edge-to-edge wajib) menggambar konten sampai ke
    // belakang navigation bar bawaan HP kalau tidak dibungkus ini.
    return SafeArea(
      top: false,
      child: Scaffold(
        body: IndexedStack(index: _index, children: tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _navigateTab,
          indicatorColor: AppColors.primary600.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available), label: 'Kehadiran'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
