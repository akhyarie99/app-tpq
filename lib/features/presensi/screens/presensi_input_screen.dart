import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/location/location_service.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/models/santri_model.dart';
import '../providers/presensi_provider.dart';

class PresensiInputScreen extends ConsumerStatefulWidget {
  const PresensiInputScreen({super.key, required this.classId, required this.className});

  final String classId;
  final String className;

  @override
  ConsumerState<PresensiInputScreen> createState() => _PresensiInputScreenState();
}

class _PresensiInputScreenState extends ConsumerState<PresensiInputScreen> {
  final Map<String, KehadiranStatus> _statuses = {};
  bool _hydrated = false;
  bool _submitting = false;

  void _hydrate(PresensiInputData data) {
    if (_hydrated) return;
    for (final student in data.students) {
      _statuses[student.id] = data.initialStatuses[student.id] ?? KehadiranStatus.hadir;
    }
    _hydrated = true;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    try {
      final position = await LocationService.instance.getCurrentPosition();

      final message = await ref.read(presensiRepositoryProvider).submit(
            classId: widget.classId,
            date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            attendances: _statuses,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(presensiInputDataProvider(widget.classId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.className)),
      body: dataAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(presensiInputDataProvider(widget.classId)),
        ),
        data: (data) {
          _hydrate(data);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.primary50,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lokasi akan diambil saat mengirim presensi. Pastikan Anda berada di area masjid.',
                        style: TextStyle(fontSize: 12, color: AppColors.primary800),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.students.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = data.students[index];
                    return _StudentAttendanceTile(
                      student: student,
                      status: _statuses[student.id] ?? KehadiranStatus.hadir,
                      onChanged: (status) => setState(() => _statuses[student.id] = status),
                    );
                  },
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(_submitting ? 'Mengirim...' : 'Ambil Lokasi & Kirim Presensi'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StudentAttendanceTile extends StatelessWidget {
  const _StudentAttendanceTile({required this.student, required this.status, required this.onChanged});

  final SantriModel student;
  final KehadiranStatus status;
  final ValueChanged<KehadiranStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary100,
                  backgroundImage: student.photo != null ? NetworkImage(student.photo!) : null,
                  child: student.photo == null
                      ? Text(student.name.substring(0, 1), style: const TextStyle(color: AppColors.primary700))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (student.nis != null)
                        Text('NIS: ${student.nis}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: KehadiranStatus.values.map((value) {
                final selected = status == value;
                return ChoiceChip(
                  label: Text(value.label),
                  selected: selected,
                  onSelected: (_) => onChanged(value),
                  selectedColor: _colorFor(value).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: selected ? _colorFor(value) : AppColors.slate500,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(KehadiranStatus status) => switch (status) {
        KehadiranStatus.hadir => AppColors.primary600,
        KehadiranStatus.izin => AppColors.gold600,
        KehadiranStatus.sakit => AppColors.gold600,
        KehadiranStatus.alfa => AppColors.danger,
      };
}
