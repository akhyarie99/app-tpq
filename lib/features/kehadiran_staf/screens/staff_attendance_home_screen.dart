import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/models/staff_attendance_today.dart';
import '../providers/staff_attendance_provider.dart';
import 'clock_mode.dart';
import 'face_enroll_screen.dart';
import 'staff_attendance_clock_screen.dart';

class StaffAttendanceHomeScreen extends ConsumerWidget {
  const StaffAttendanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(staffAttendanceTodayProvider);
    final enrolledAsync = ref.watch(faceEnrollStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.face_retouching_natural_outlined),
            tooltip: 'Daftarkan / Perbarui Wajah',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceEnrollScreen()));
              ref.invalidate(faceEnrollStatusProvider);
            },
          ),
        ],
      ),
      body: todayAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString(), onRetry: () => ref.invalidate(staffAttendanceTodayProvider)),
        data: (attendance) => _Body(attendance: attendance, enrolledAsync: enrolledAsync),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.attendance, required this.enrolledAsync});

  final StaffAttendanceToday? attendance;
  final AsyncValue<bool> enrolledAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrolled = enrolledAsync.valueOrNull ?? false;
    final hasClockedIn = attendance?.hasClockedIn ?? false;
    final hasClockedOut = attendance?.hasClockedOut ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!enrolled)
          Card(
            color: AppColors.warning.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Wajah Anda belum terdaftar. Daftarkan dulu lewat ikon di pojok kanan atas sebelum bisa presensi.'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now()), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                _StatusRow(
                  label: 'Masuk',
                  time: attendance?.clockIn,
                  location: attendance?.clockInLocation,
                ),
                const Divider(height: 24),
                _StatusRow(
                  label: 'Keluar',
                  time: attendance?.clockOut,
                  location: attendance?.clockOutLocation,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!hasClockedIn)
          FilledButton.icon(
            icon: const Icon(Icons.login_rounded),
            label: const Text('Presensi Masuk'),
            onPressed: enrolled ? () => _openClock(context, ref, ClockMode.clockIn) : null,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          )
        else if (!hasClockedOut)
          FilledButton.icon(
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Presensi Keluar'),
            onPressed: enrolled ? () => _openClock(context, ref, ClockMode.clockOut) : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.gold600,
            ),
          )
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(child: Text('Presensi hari ini sudah lengkap (masuk & keluar). Sampai jumpa besok!')),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openClock(BuildContext context, WidgetRef ref, ClockMode mode) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => StaffAttendanceClockScreen(mode: mode)));
    ref.invalidate(staffAttendanceTodayProvider);
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, this.time, this.location});

  final String label;
  final DateTime? time;
  final String? location;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          time != null ? Icons.check_circle : Icons.radio_button_unchecked,
          color: time != null ? AppColors.success : AppColors.slate400,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (location != null) Text(location!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Text(
          time != null ? DateFormat('HH:mm', 'id_ID').format(time!.toLocal()) : '--:--',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
