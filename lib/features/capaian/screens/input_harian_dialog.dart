import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/capaian_provider.dart';

class InputHarianDialog extends ConsumerStatefulWidget {
  const InputHarianDialog({super.key, required this.classId, required this.studentId});

  final String classId;
  final String studentId;

  @override
  ConsumerState<InputHarianDialog> createState() => _InputHarianDialogState();
}

class _InputHarianDialogState extends ConsumerState<InputHarianDialog> {
  final _formKey = GlobalKey<FormState>();
  final _halamanController = TextEditingController();
  final _surahController = TextEditingController();
  final _ayatAwalController = TextEditingController();
  final _ayatAkhirController = TextEditingController();
  final _catatanController = TextEditingController();

  String _method = 'iqro';
  int _jilid = 1;
  String _keterangan = 'lancar';
  bool _saving = false;

  @override
  void dispose() {
    _halamanController.dispose();
    _surahController.dispose();
    _ayatAwalController.dispose();
    _ayatAkhirController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(capaianRepositoryProvider).inputDailyProgress(
            studentId: widget.studentId,
            classId: widget.classId,
            date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            method: _method,
            keterangan: _keterangan,
            jilid: _method == 'iqro' ? _jilid : null,
            halaman: _halamanController.text.trim().isEmpty ? null : int.tryParse(_halamanController.text),
            surah: _method == 'quran' ? _surahController.text.trim() : null,
            ayatAwal: _method == 'quran' ? int.tryParse(_ayatAwalController.text) : null,
            ayatAkhir: _method == 'quran' ? int.tryParse(_ayatAkhirController.text) : null,
            catatan: _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim(),
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
            Text('Input Mengaji Hari Ini', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
              style: const TextStyle(color: AppColors.slate500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'iqro', label: Text('Iqro')),
                ButtonSegment(value: 'quran', label: Text("Al-Qur'an")),
              ],
              selected: {_method},
              onSelectionChanged: (value) => setState(() => _method = value.first),
            ),
            const SizedBox(height: 12),
            if (_method == 'iqro') ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _jilid,
                      decoration: const InputDecoration(labelText: 'Jilid'),
                      items: List.generate(6, (i) => i + 1)
                          .map((n) => DropdownMenuItem(value: n, child: Text('Jilid $n')))
                          .toList(),
                      onChanged: (value) => setState(() => _jilid = value ?? 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _halamanController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Halaman'),
                      validator: (value) => (int.tryParse(value ?? '') == null) ? 'Wajib angka' : null,
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextFormField(
                controller: _surahController,
                decoration: const InputDecoration(labelText: 'Surat'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ayatAwalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ayat Awal'),
                      validator: (value) => (int.tryParse(value ?? '') == null) ? 'Wajib angka' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ayatAkhirController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ayat Akhir'),
                      validator: (value) => (int.tryParse(value ?? '') == null) ? 'Wajib angka' : null,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'lancar', label: Text('Lancar')),
                ButtonSegment(value: 'ulang', label: Text('Ulang')),
              ],
              selected: {_keterangan},
              onSelectionChanged: (value) => setState(() => _keterangan = value.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _catatanController,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan & Kabari Wali'),
            ),
          ],
        ),
      ),
    );
  }
}
