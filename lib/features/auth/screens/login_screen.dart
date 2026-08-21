import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/flavor_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _biometricSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Tawarkan prompt biometrik begitu layar muncul kalau memang ada sesi
    // terkunci yang menunggu — hanya sekali, jadi aman di initState (bukan
    // build) walau LoginScreen tetap ditampilkan lagi setelah gagal/batal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(authProvider).status == AuthStatus.locked) {
        _unlockWithBiometric();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _unlockWithBiometric() async {
    if (_biometricSubmitting) return;
    setState(() => _biometricSubmitting = true);

    final success = await ref.read(authProvider.notifier).unlockWithBiometric();
    if (!mounted) return;
    setState(() => _biometricSubmitting = false);

    if (!success) {
      final error = ref.read(authProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;
    // "locked" = ada sesi tersimpan + biometrik diaktifkan — tawarkan
    // pintasan sidik jari/wajah di bawah tombol Masuk, tanpa menyembunyikan
    // form nomor HP/password (tetap bisa dipakai kalau sensor gagal/malas).
    final showBiometricShortcut = authState.status == AuthStatus.locked;

    // Login selalu tema terang & latar putih, senada dengan latar logo — terlepas
    // dari mode gelap/terang sistem HP (yang tetap berlaku di layar-layar lain).
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      FlavorConfig.instance.logoAssetPath,
                      height: 140,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      FlavorConfig.instance.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.slate500),
                    ),
                    const SizedBox(height: 32),
                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Nomor HP', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Nomor HP wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Kata sandi wajib diisi' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    _GradientButton(
                      onPressed: isLoading ? null : _submit,
                      loading: isLoading,
                      label: 'Masuk',
                    ),
                    if (showBiometricShortcut) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('atau', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(40),
                              onTap: _biometricSubmitting ? null : _unlockWithBiometric,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary600.withValues(alpha: 0.1),
                                ),
                                child: _biometricSubmitting
                                    ? const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary600),
                                      )
                                    : const Icon(Icons.fingerprint, size: 36, color: AppColors.primary600),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Masuk dengan Biometrik',
                              style: TextStyle(color: AppColors.primary600, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onPressed, required this.loading, required this.label});

  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: disabled
              ? [AppColors.slate400, AppColors.slate400]
              : const [Color(0xFF1E3A8A), Color(0xFF60A5FA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
          ),
        ),
      ),
    );
  }
}
