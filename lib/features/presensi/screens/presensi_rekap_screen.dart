import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../providers/presensi_provider.dart';

class PresensiRekapScreen extends ConsumerStatefulWidget {
  const PresensiRekapScreen({super.key, required this.classId, required this.className});

  final String classId;
  final String className;

  @override
  ConsumerState<PresensiRekapScreen> createState() => _PresensiRekapScreenState();
}

class _PresensiRekapScreenState extends ConsumerState<PresensiRekapScreen> {
  late DateTime _period = DateTime.now();

  void _shiftMonth(int delta) {
    setState(() => _period = DateTime(_period.year, _period.month + delta, 1));
  }

  @override
  Widget build(BuildContext context) {
    final params = (classId: widget.classId, month: _period.month, year: _period.year);
    final rekapAsync = ref.watch(rekapProvider(params));

    return Scaffold(
      appBar: AppBar(title: Text('Rekap - ${widget.className}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left_rounded)),
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(_period),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right_rounded)),
              ],
            ),
          ),
          Expanded(
            child: rekapAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(rekapProvider(params)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Belum ada santri di kelas ini.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'Hadir ${item.presentCount} · Izin ${item.permissionCount} · '
                          'Sakit ${item.sickCount} · Alfa ${item.absentCount}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${item.percent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.percent >= 80 ? AppColors.primary600 : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
