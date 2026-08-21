import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/models/staff_attendance_today.dart';
import '../providers/staff_attendance_provider.dart';

/// Tab "Kehadiran" di [HomeShell] — riwayat presensi masuk/keluar milik
/// sendiri (bukan rekap semua staf, itu ada di menu web admin untuk role
/// yang berwenang).
class KehadiranTab extends ConsumerWidget {
  const KehadiranTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(staffAttendanceHistoryProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(staffAttendanceHistoryProvider);
          await ref.read(staffAttendanceHistoryProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Riwayat Kehadiran', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMMM y', 'id_ID').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            historyAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(24), child: LoadingView()),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ErrorView(message: error.toString(), onRetry: () => ref.invalidate(staffAttendanceHistoryProvider)),
              ),
              data: (items) => _HistoryList(items: items),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<StaffAttendanceToday> items;

  const _HistoryList({required this.items});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = items.where((a) {
      final d = DateTime.parse(a.date);
      return d.year == now.year && d.month == now.month;
    }).toList();
    final hadir = thisMonth.where((a) => a.hasClockedIn).length;
    final lengkap = thisMonth.where((a) => a.hasClockedIn && a.hasClockedOut).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _SummaryChip(value: hadir, label: 'Hadir', color: AppColors.primary600, icon: Icons.event_available)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryChip(value: lengkap, label: 'Lengkap', color: AppColors.gold600, icon: Icons.check_circle)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Riwayat', style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Text('Belum ada riwayat presensi', style: TextStyle(color: Colors.grey.shade600)),
            ),
          )
        else
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.hasClockedIn ? AppColors.primary100 : AppColors.slate100,
                      child: Icon(
                        item.hasClockedIn ? Icons.check_circle : Icons.remove_circle_outline,
                        color: item.hasClockedIn ? AppColors.primary700 : AppColors.slate400,
                      ),
                    ),
                    title: Text(
                      DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.parse(item.date)),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(
                      'Masuk ${item.clockIn != null ? DateFormat('HH:mm').format(item.clockIn!.toLocal()) : '--:--'} '
                      '· Keluar ${item.clockOut != null ? DateFormat('HH:mm').format(item.clockOut!.toLocal()) : '--:--'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              )),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryChip({required this.value, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text('$value', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.85), fontSize: 10)),
        ],
      ),
    );
  }
}
