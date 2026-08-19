import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../capaian/screens/capaian_kelas_screen.dart';
import '../../kehadiran_staf/screens/staff_attendance_home_screen.dart';
import '../../presensi/screens/presensi_input_screen.dart';
import '../../presensi/screens/presensi_kelas_screen.dart';
import '../../webview/screens/webview_screen.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.masjid.name ?? 'SiMasjid'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Keluar'),
                  content: const Text('Yakin ingin keluar dari akun ini?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: dashboardAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(message: error.toString(), onRetry: () => ref.invalidate(dashboardProvider)),
          data: (data) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Assalamu\'alaikum, ${user?.name ?? ''}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.4,
                children: [
                  StatCard(label: 'Kelas Diampu', value: '${data.totalClasses}', icon: Icons.groups_rounded),
                  StatCard(
                    label: 'Total Santri',
                    value: '${data.totalStudents}',
                    icon: Icons.school_rounded,
                    color: AppColors.gold600,
                  ),
                  StatCard(
                    label: 'Hadir Hari Ini',
                    value: '${data.presentToday}',
                    icon: Icons.check_circle_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Aksi Cepat'),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.fact_check_rounded,
                      label: 'Presensi',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PresensiKelasScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.auto_stories_rounded,
                      label: 'Capaian Santri',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CapaianKelasScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _QuickAction(
                icon: Icons.face_retouching_natural_rounded,
                label: 'Presensi Saya (Masuk/Keluar Mengajar)',
                fullWidth: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffAttendanceHomeScreen())),
              ),
              const SizedBox(height: 8),
              _QuickAction(
                icon: Icons.dashboard_customize_rounded,
                label: 'Menu Admin Lengkap (Web)',
                fullWidth: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WebviewScreen(path: '/admin/dashboard', title: 'Menu Admin'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(title: 'Kelas Saya (${data.classes.length})'),
              ...data.classes.map(
                (kelas) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary100,
                      child: Icon(Icons.groups_rounded, color: AppColors.primary700),
                    ),
                    title: Text(kelas.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${kelas.studentCount} santri'),
                    trailing: kelas.attendanceSubmittedToday
                        ? const Chip(
                            label: Text('Sudah presensi', style: TextStyle(fontSize: 11)),
                            backgroundColor: AppColors.primary100,
                            side: BorderSide.none,
                          )
                        : const Chip(
                            label: Text('Belum presensi', style: TextStyle(fontSize: 11)),
                            backgroundColor: AppColors.slate100,
                            side: BorderSide.none,
                          ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PresensiInputScreen(classId: kelas.id, className: kelas.name),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.fullWidth = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary600),
              const SizedBox(width: 10),
              Flexible(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
