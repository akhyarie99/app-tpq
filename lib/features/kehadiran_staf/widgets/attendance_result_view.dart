import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Layar hasil presensi (sukses/gagal) dipakai oleh StaffAttendanceClockScreen.
class AttendanceResultView extends StatelessWidget {
  final bool success;
  final String title;
  final String message;
  final List<MapEntry<String, String>> details;
  final List<String> checklist;
  final VoidCallback? onRetry;
  final VoidCallback onDone;
  final String doneLabel;

  const AttendanceResultView.success({
    super.key,
    required this.title,
    required this.message,
    required this.details,
    required this.onDone,
    this.doneLabel = 'Selesai',
  })  : success = true,
        checklist = const [],
        onRetry = null;

  const AttendanceResultView.failure({
    super.key,
    required this.title,
    required this.message,
    required this.checklist,
    required this.onRetry,
    required this.onDone,
    this.doneLabel = 'Kembali ke Beranda',
  })  : success = false,
        details = const [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: success ? AppColors.success.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.1),
              ),
              child: Icon(
                success ? Icons.check_circle : Icons.close_rounded,
                color: success ? AppColors.success : AppColors.danger,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: success ? AppColors.success : AppColors.danger,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            if (success)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: details
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(e.key, style: TextStyle(color: Colors.grey.shade600))),
                                Flexible(
                                  child: Text(
                                    e.value,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pastikan:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                    const SizedBox(height: 8),
                    ...checklist.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel, color: AppColors.danger, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item, style: const TextStyle(color: AppColors.danger))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            const Spacer(),
            if (!success && onRetry != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            if (!success && onRetry != null) const SizedBox(height: 8),
            if (success)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(doneLabel),
                ),
              )
            else
              TextButton(onPressed: onDone, child: Text(doneLabel)),
          ],
        ),
      ),
    );
  }
}
