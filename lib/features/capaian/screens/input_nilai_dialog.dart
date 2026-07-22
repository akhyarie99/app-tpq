import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../data/models/grade_model.dart';
import '../providers/capaian_provider.dart';

class InputNilaiDialog extends ConsumerStatefulWidget {
  const InputNilaiDialog({
    super.key,
    required this.classId,
    required this.studentId,
    required this.subjects,
    required this.semesterId,
  });

  final String classId;
  final String studentId;
  final List<SubjectModel> subjects;
  final String? semesterId;

  @override
  ConsumerState<InputNilaiDialog> createState() => _InputNilaiDialogState();
}

class _InputNilaiDialogState extends ConsumerState<InputNilaiDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _subjectId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.subjects.first.id;
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || widget.semesterId == null) {
      if (widget.semesterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada semester aktif untuk menyimpan nilai.'), backgroundColor: AppColors.danger),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(capaianRepositoryProvider).inputNilai(
            studentId: widget.studentId,
            classId: widget.classId,
            subjectId: _subjectId!,
            semesterId: widget.semesterId!,
            score: num.parse(_scoreController.text),
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Input Nilai', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _subjectId,
              decoration: const InputDecoration(labelText: 'Mata Pelajaran'),
              items: widget.subjects
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (value) => setState(() => _subjectId = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _scoreController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Nilai (0-100)'),
              validator: (value) {
                final score = num.tryParse(value ?? '');
                if (score == null) return 'Nilai wajib diisi angka';
                if (score < 0 || score > 100) return 'Nilai harus antara 0-100';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
