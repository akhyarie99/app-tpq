import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/models/daily_progress_model.dart';
import '../data/models/grade_model.dart';
import '../data/models/hafalan_model.dart';
import '../providers/capaian_provider.dart';
import 'input_hafalan_dialog.dart';
import 'input_harian_dialog.dart';
import 'input_nilai_dialog.dart';

class CapaianDetailScreen extends ConsumerStatefulWidget {
  const CapaianDetailScreen({super.key, required this.classId, required this.studentId, required this.studentName});

  final String classId;
  final String studentId;
  final String studentName;

  @override
  ConsumerState<CapaianDetailScreen> createState() => _CapaianDetailScreenState();
}

class _CapaianDetailScreenState extends ConsumerState<CapaianDetailScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openInputNilai(CapaianDetail detail) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InputNilaiDialog(
        classId: widget.classId,
        studentId: widget.studentId,
        subjects: detail.subjects,
        semesterId: detail.activeSemesterId,
      ),
    );

    if (saved == true) {
      ref.invalidate(capaianDetailProvider(widget.studentId));
    }
  }

  Future<void> _openInputHafalan() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InputHafalanDialog(studentId: widget.studentId),
    );

    if (saved == true) {
      ref.invalidate(hafalanProvider(widget.studentId));
    }
  }

  Future<void> _openInputHarian() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InputHarianDialog(classId: widget.classId, studentId: widget.studentId),
    );

    if (saved == true) {
      ref.invalidate(dailyProgressProvider(widget.studentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tersimpan — wali murid sudah diberi tahu.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(capaianDetailProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Harian'), Tab(text: 'Nilai'), Tab(text: 'Hafalan')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Consumer(builder: (context, ref, _) {
            final dailyAsync = ref.watch(dailyProgressProvider(widget.studentId));
            return dailyAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(dailyProgressProvider(widget.studentId)),
              ),
              data: (items) => _HarianTab(items: items, onAdd: _openInputHarian),
            );
          }),
          detailAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(capaianDetailProvider(widget.studentId)),
            ),
            data: (detail) => _GradesTab(detail: detail, onAdd: () => _openInputNilai(detail)),
          ),
          Consumer(builder: (context, ref, _) {
            final hafalanAsync = ref.watch(hafalanProvider(widget.studentId));
            return hafalanAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(hafalanProvider(widget.studentId)),
              ),
              data: (items) => _HafalanTab(items: items, onAdd: _openInputHafalan),
            );
          }),
        ],
      ),
    );
  }
}

class _GradesTab extends StatelessWidget {
  const _GradesTab({required this.detail, required this.onAdd});

  final CapaianDetail detail;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (detail.activeSemesterName != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: AppColors.primary50,
            child: Text(
              'Semester aktif: ${detail.activeSemesterName}',
              style: const TextStyle(fontSize: 12, color: AppColors.primary800),
            ),
          ),
        Expanded(
          child: detail.grades.isEmpty
              ? const Center(child: Text('Belum ada nilai tercatat.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: detail.grades.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final grade = detail.grades[index];
                    return Card(
                      child: ListTile(
                        title: Text(grade.subjectName ?? '-'),
                        subtitle: grade.description != null ? Text(grade.description!) : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${grade.score}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (grade.gradeLetter != null)
                              Text(grade.gradeLetter!, style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: detail.subjects.isEmpty ? null : onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Input / Update Nilai'),
          ),
        ),
      ],
    );
  }
}

class _HafalanTab extends StatelessWidget {
  const _HafalanTab({required this.items, required this.onAdd});

  final List<HafalanModel> items;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Belum ada progres hafalan.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.surahName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                _StatusBadge(status: item.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: item.progress,
                              backgroundColor: AppColors.slate200,
                              color: AppColors.primary600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.memorizedAyah}/${item.totalAyah} ayat',
                              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Input / Update Hafalan'),
          ),
        ),
      ],
    );
  }
}

class _HarianTab extends StatelessWidget {
  const _HarianTab({required this.items, required this.onAdd});

  final List<DailyProgressModel> items;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Belum ada catatan mengaji harian.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.summary),
                        subtitle: Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.parse(item.date))),
                        trailing: _KeteranganBadge(keterangan: item.keterangan),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Input Mengaji Hari Ini'),
          ),
        ),
      ],
    );
  }
}

class _KeteranganBadge extends StatelessWidget {
  const _KeteranganBadge({required this.keterangan});

  final String keterangan;

  @override
  Widget build(BuildContext context) {
    final isLancar = keterangan == 'lancar';
    final color = isLancar ? AppColors.primary600 : AppColors.gold600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(isLancar ? 'Lancar' : 'Ulang', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'hafal' => AppColors.primary600,
      'sedang' => AppColors.gold600,
      _ => AppColors.slate500,
    };

    final label = switch (status) {
      'hafal' => 'Hafal',
      'sedang' => 'Sedang',
      _ => 'Belum',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
