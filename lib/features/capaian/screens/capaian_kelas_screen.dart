import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../presensi/providers/presensi_provider.dart';
import 'capaian_santri_screen.dart';

class CapaianKelasScreen extends ConsumerWidget {
  const CapaianKelasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Daftar kelas sama dengan modul presensi (kelas yang diampu ustadz ini).
    final kelasAsync = ref.watch(kelasListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Capaian Santri')),
      body: kelasAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString(), onRetry: () => ref.invalidate(kelasListProvider)),
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(child: Text('Belum ada kelas yang Anda ampu.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final kelas = classes[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary100,
                    child: Icon(Icons.auto_stories_rounded, color: AppColors.primary700),
                  ),
                  title: Text(kelas.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${kelas.studentCount} santri'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CapaianSantriScreen(classId: kelas.id, className: kelas.name),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
