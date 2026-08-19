import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
import '../data/models/santri_lookup_model.dart';
import '../providers/capaian_provider.dart';
import 'capaian_detail_screen.dart';

final _uuidRe = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

class ScanSantriScreen extends ConsumerStatefulWidget {
  const ScanSantriScreen({super.key});

  @override
  ConsumerState<ScanSantriScreen> createState() => _ScanSantriScreenState();
}

class _ScanSantriScreenState extends ConsumerState<ScanSantriScreen> {
  final _searchController = TextEditingController();
  final _scannerController = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);

  List<SantriLookupModel> _results = [];
  bool _searching = false;
  bool _resolving = false;

  @override
  void dispose() {
    _searchController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.trim().length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() => _searching = true);
    try {
      final results = await ref.read(capaianRepositoryProvider).searchStudents(value.trim());
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      // Biarkan hasil kosong kalau pencarian gagal, tidak perlu ganggu ustadz dengan error.
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_resolving || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || !_uuidRe.hasMatch(value)) return;

    await _resolveStudent(value);
  }

  Future<void> _resolveStudent(String studentId) async {
    setState(() => _resolving = true);
    try {
      final student = await ref.read(capaianRepositoryProvider).findStudent(studentId);
      if (!mounted) return;
      _openStudent(student);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Santri tidak ditemukan: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _openStudent(SantriLookupModel student) {
    if (student.classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Santri ini belum terdaftar di kelas aktif.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CapaianDetailScreen(classId: student.classId!, studentId: student.id, studentName: student.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan / Cari Santri')),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(controller: _scannerController, onDetect: _onDetect),
                Container(
                  margin: const EdgeInsets.all(48),
                  decoration: BoxDecoration(border: Border.all(color: Colors.white70, width: 2), borderRadius: BorderRadius.circular(16)),
                ),
                if (_resolving) const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Arahkan kamera ke QR di kartu/buku mutabaah santri', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Atau ketik nama/NIS santri...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const SizedBox.shrink()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = _results[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                        title: Text(student.name),
                        subtitle: Text('${student.nis} · ${student.className ?? 'Belum ada kelas'}'),
                        onTap: () => _openStudent(student),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
