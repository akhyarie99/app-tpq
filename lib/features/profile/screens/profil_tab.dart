import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/flavor_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../kehadiran_staf/screens/face_enroll_screen.dart';
import '../../webview/screens/webview_screen.dart';

/// Tab "Profil" di [HomeShell] — identitas pengguna & pintasan akun.
class ProfilTab extends ConsumerStatefulWidget {
  const ProfilTab({super.key});

  @override
  ConsumerState<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends ConsumerState<ProfilTab> {
  bool? _biometricEnabled;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    final enabled = await ref.read(authProvider.notifier).isBiometricEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleBiometric(bool value) async {
    final auth = ref.read(authProvider.notifier);

    if (value) {
      // Minta verifikasi biometrik dulu sebelum mengaktifkan, supaya user
      // tidak "mengunci diri sendiri" pakai sidik jari yang ternyata gagal
      // dibaca sensor.
      try {
        final confirmed = await ref.read(biometricServiceProvider).authenticate(
              reason: 'Verifikasi biometrik untuk mengaktifkan fitur ini',
            );
        if (!confirmed) return;
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        return;
      }
    }

    await auth.setBiometricEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    // Kalau biometrik aktif, "Keluar" cuma mengunci app (token tetap
    // tersimpan) — jelaskan ini di dialog supaya tidak mengejutkan user yang
    // mengira ini logout penuh (lihat AuthNotifier.logout).
    final content = _biometricEnabled == true
        ? 'Aplikasi akan terkunci. Anda bisa masuk lagi dengan sidik jari/wajah tanpa ketik password.'
        : 'Anda yakin ingin keluar dari akun ini?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Keluar')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  static const _roleLabels = {
    'super_admin': 'Super Admin',
    'admin': 'Admin',
    'bendahara': 'Bendahara',
    'sekretaris': 'Sekretaris',
    'ustadz': 'Ustadz',
    'viewer': 'Viewer',
  };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final initials = (user?.name ?? '-').trim().isEmpty
        ? '-'
        : user!.name.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join().toUpperCase();
    final roleLabel = _roleLabels[user?.role] ?? user?.role ?? '-';

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profil Saya', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        backgroundImage: user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                        child: user?.avatar == null
                            ? Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? '-', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(roleLabel, style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    _InfoRow(icon: Icons.phone_outlined, label: 'No. HP', value: user?.phone ?? '-'),
                    _InfoRow(icon: Icons.mosque_outlined, label: 'Masjid/TPQ', value: user?.masjid.name ?? '-'),
                  ],
                ),
              ),
            ),
          ),
          if (authState.biometricAvailable) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Keamanan', style: Theme.of(context).textTheme.titleMedium),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint, color: AppColors.primary600),
              title: const Text('Login Biometrik', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Buka aplikasi dengan sidik jari/wajah', style: TextStyle(fontSize: 12)),
              value: _biometricEnabled ?? false,
              onChanged: _biometricEnabled == null ? null : _toggleBiometric,
              activeTrackColor: AppColors.primary600,
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Menu', style: Theme.of(context).textTheme.titleMedium),
          ),
          _SettingsTile(
            icon: Icons.face_retouching_natural_outlined,
            title: 'Daftarkan / Perbarui Wajah',
            subtitle: 'Untuk presensi masuk/keluar',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaceEnrollScreen())),
          ),
          _SettingsTile(
            icon: Icons.apps_outlined,
            title: 'Menu Admin Lengkap',
            subtitle: 'Buka semua menu lewat web',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WebviewScreen(path: '/admin/dashboard', title: 'Menu Admin')),
            ),
          ),
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profil',
            subtitle: 'Ubah data diri lewat web',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WebviewScreen(path: '/profil', title: 'Edit Profil')),
            ),
          ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: FlavorConfig.instance.appName,
            onTap: null,
          ),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Keluar',
            subtitle: 'Keluar dari akun ini',
            iconColor: AppColors.danger,
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary600),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary600),
      title: Text(title, style: TextStyle(color: iconColor, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
