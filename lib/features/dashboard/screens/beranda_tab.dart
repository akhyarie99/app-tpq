import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../capaian/screens/capaian_kelas_screen.dart';
import '../../kehadiran_staf/data/models/staff_attendance_today.dart';
import '../../kehadiran_staf/providers/staff_attendance_provider.dart';
import '../../kehadiran_staf/screens/clock_mode.dart';
import '../../kehadiran_staf/screens/face_enroll_screen.dart';
import '../../kehadiran_staf/screens/staff_attendance_clock_screen.dart';
import '../../presensi/screens/presensi_kelas_screen.dart';
import '../../webview/screens/webview_screen.dart';
import '../data/models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'Selamat Pagi';
  if (hour < 15) return 'Selamat Siang';
  if (hour < 18) return 'Selamat Sore';
  return 'Selamat Malam';
}

/// Tab "Beranda" di [HomeShell] — status presensi hari ini, menu cepat, dan
/// ringkasan kelas. [onNavigateTab] dipakai supaya kartu di sini bisa membuka
/// tab lain di shell yang sama (mis. Kehadiran) alih-alih push layar baru.
///
/// "Menu Lainnya" (WebviewScreen) sengaja dibuka lewat Navigator.push, BUKAN
/// sebagai tab shell — WebviewScreen sudah punya sidebar/menu web sendiri,
/// jadi kalau ikut ditaruh di shell, bottom nav bar akan tetap tampil di atas
/// sidebar itu dan terlihat dobel/berantakan.
class BerandaTab extends ConsumerWidget {
  final ValueChanged<int> onNavigateTab;

  const BerandaTab({super.key, required this.onNavigateTab});

  Future<void> _startClock(BuildContext context, WidgetRef ref, StaffAttendanceToday? today, bool enrolled) async {
    if (!enrolled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daftarkan wajah Anda dulu lewat menu "Daftar Wajah" sebelum bisa presensi.')),
      );
      return;
    }
    if (today?.hasClockedOut == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda sudah menyelesaikan presensi hari ini (masuk & keluar).')),
      );
      return;
    }
    final mode = today?.hasClockedIn != true ? ClockMode.clockIn : ClockMode.clockOut;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => StaffAttendanceClockScreen(mode: mode)));
    ref.invalidate(staffAttendanceTodayProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final dashboardAsync = ref.watch(dashboardProvider);
    final todayAsync = ref.watch(staffAttendanceTodayProvider);
    final enrolledAsync = ref.watch(faceEnrollStatusProvider);
    final enrolled = enrolledAsync.valueOrNull ?? false;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(staffAttendanceTodayProvider);
          ref.invalidate(faceEnrollStatusProvider);
          await ref.read(dashboardProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(name: user?.name ?? '-', masjidName: user?.masjid.name, avatarUrl: user?.avatar),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StatusCard(
                  today: todayAsync.valueOrNull,
                  isLoading: todayAsync.isLoading,
                  enrolled: enrolled,
                  onClock: () => _startClock(context, ref, todayAsync.valueOrNull, enrolled),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Menu Cepat', style: Theme.of(context).textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _MenuTile(
                    icon: Icons.fact_check_outlined,
                    label: 'Presensi\nKelas',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PresensiKelasScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.auto_stories_outlined,
                    label: 'Capaian\nSantri',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CapaianKelasScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.bar_chart_outlined,
                    label: 'Riwayat\nKehadiran',
                    onTap: () => onNavigateTab(1),
                  ),
                  _MenuTile(
                    icon: Icons.face_retouching_natural_outlined,
                    label: 'Daftar\nWajah',
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceEnrollScreen()));
                      ref.invalidate(faceEnrollStatusProvider);
                    },
                  ),
                  _MenuTile(
                    icon: Icons.apps_outlined,
                    label: 'Menu\nLainnya',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WebviewScreen(path: '/admin/dashboard', title: 'Menu Admin'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            dashboardAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(24), child: LoadingView()),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ErrorView(message: error.toString(), onRetry: () => ref.invalidate(dashboardProvider)),
              ),
              data: (data) => _ClassSummary(data: data),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String? masjidName;
  final String? avatarUrl;

  const _Header({required this.name, this.masjidName, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '-'
        : name.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 56),
      decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_greeting()},', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (masjidName != null)
                    Text(masjidName!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final StaffAttendanceToday? today;
  final bool isLoading;
  final bool enrolled;
  final VoidCallback onClock;

  const _StatusCard({required this.today, required this.isLoading, required this.enrolled, required this.onClock});

  @override
  Widget build(BuildContext context) {
    final hasClockedIn = today?.hasClockedIn == true;
    final hasClockedOut = today?.hasClockedOut == true;

    final String statusText;
    final Color statusColor;
    if (hasClockedOut) {
      statusText = 'Presensi Selesai';
      statusColor = AppColors.success;
    } else if (hasClockedIn) {
      statusText = 'Sudah Absen Masuk';
      statusColor = AppColors.primary600;
    } else {
      statusText = 'Belum Absen';
      statusColor = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Kehadiran', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(statusText, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statusColor)),
          const SizedBox(height: 4),
          Text(DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now()), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const Divider(height: 24),
          if (isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
          else
            Row(
              children: [
                Expanded(child: _TimeBlock(label: 'Masuk', time: today?.clockIn)),
                Container(width: 1, height: 32, color: Colors.grey.shade200),
                Expanded(child: _TimeBlock(label: 'Keluar', time: today?.clockOut)),
              ],
            ),
          if (!enrolled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Wajah belum terdaftar. Daftarkan lewat menu "Daftar Wajah".', style: TextStyle(fontSize: 11, color: AppColors.warning)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(hasClockedIn ? Icons.logout : Icons.login),
              label: Text(hasClockedIn ? 'Absen Keluar' : 'Absen Masuk'),
              onPressed: hasClockedOut ? null : onClock,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final String label;
  final DateTime? time;

  const _TimeBlock({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          time != null ? DateFormat('HH:mm').format(time!.toLocal()) : '--:--',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary600, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassSummary extends StatelessWidget {
  final DashboardData data;

  const _ClassSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _StatChip(label: 'Kelas Diampu', value: '${data.totalClasses}', icon: Icons.groups_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Total Santri', value: '${data.totalStudents}', icon: Icons.school_rounded, color: AppColors.gold600)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(label: 'Hadir Hari Ini', value: '${data.presentToday}', icon: Icons.check_circle_rounded)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Kelas Saya (${data.classes.length})', style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        ...List.generate(data.classes.length, (i) {
          final kelas = data.classes[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  MaterialPageRoute(builder: (_) => const PresensiKelasScreen()),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatChip({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary600;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 16)),
          Text(label, style: TextStyle(color: c.withValues(alpha: 0.85), fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
