import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/capaian_provider.dart';

class InputHafalanDialog extends ConsumerStatefulWidget {
  const InputHafalanDialog({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<InputHafalanDialog> createState() => _InputHafalanDialogState();
}

class _InputHafalanDialogState extends ConsumerState<InputHafalanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _surahNumberController = TextEditingController();
  final _surahNameController = TextEditingController();
  final _totalAyahController = TextEditingController();
  final _memorizedAyahController = TextEditingController();
  String _status = 'sedang';
  bool _saving = false;

  @override
  void dispose() {
    _surahNumberController.dispose();
    _surahNameController.dispose();
    _totalAyahController.dispose();
    _memorizedAyahController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(capaianRepositoryProvider).updateHafalan(
            studentId: widget.studentId,
            surahNumber: int.parse(_surahNumberController.text),
            surahName: _surahNameController.text.trim(),
            totalAyah: int.parse(_totalAyahController.text),
            memorizedAyah: int.parse(_memorizedAyahController.text),
            status: _status,
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
            Text('Input Hafalan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _surahNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'No. Surah (1-114)'),
                    validator: (value) {
                      final n = int.tryParse(value ?? '');
                      if (n == null || n < 1 || n > 114) return 'Wajib 1-114';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _surahNameController,
                    decoration: const InputDecoration(labelText: 'Nama Surah'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalAyahController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total Ayat'),
                    validator: (value) => (int.tryParse(value ?? '') == null) ? 'Wajib angka' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _memorizedAyahController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ayat Dihafal'),
                    validator: (value) => (int.tryParse(value ?? '') == null) ? 'Wajib angka' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'belum', child: Text('Belum')),
                DropdownMenuItem(value: 'sedang', child: Text('Sedang')),
                DropdownMenuItem(value: 'hafal', child: Text('Hafal')),
              ],
              onChanged: (value) => setState(() => _status = value ?? 'sedang'),
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
