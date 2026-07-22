import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../providers/presensi_provider.dart';
import 'presensi_input_screen.dart';
import 'presensi_rekap_screen.dart';

class PresensiKelasScreen extends ConsumerWidget {
  const PresensiKelasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kelasAsync = ref.watch(kelasListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Presensi Santri')),
      body: kelasAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(kelasListProvider),
        ),
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(child: Text('Belum ada kelas yang Anda ampu.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(kelasListProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final kelas = classes[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary100,
                      child: const Icon(Icons.groups_rounded, color: AppColors.primary700),
                    ),
                    title: Text(kelas.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${kelas.studentCount} santri'),
                    trailing: IconButton(
                      icon: const Icon(Icons.bar_chart_rounded),
                      tooltip: 'Rekap Bulanan',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PresensiRekapScreen(classId: kelas.id, className: kelas.name),
                        ),
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PresensiInputScreen(classId: kelas.id, className: kelas.name),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
