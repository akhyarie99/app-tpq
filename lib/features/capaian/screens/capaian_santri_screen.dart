import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../providers/capaian_provider.dart';
import 'capaian_detail_screen.dart';

class CapaianSantriScreen extends ConsumerWidget {
  const CapaianSantriScreen({super.key, required this.classId, required this.className});

  final String classId;
  final String className;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final santriAsync = ref.watch(capaianSantriListProvider(classId));

    return Scaffold(
      appBar: AppBar(title: Text(className)),
      body: santriAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(capaianSantriListProvider(classId)),
        ),
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('Belum ada santri di kelas ini.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary100,
                    backgroundImage: student.photo != null ? NetworkImage(student.photo!) : null,
                    child: student.photo == null
                        ? Text(student.name.substring(0, 1), style: const TextStyle(color: AppColors.primary700))
                        : null,
                  ),
                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: student.nis != null ? Text('NIS: ${student.nis}') : null,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CapaianDetailScreen(classId: classId, studentId: student.id, studentName: student.name),
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
