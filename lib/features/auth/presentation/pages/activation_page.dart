import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../data/services/license_service.dart';

class ActivationPage extends ConsumerStatefulWidget {
  const ActivationPage({super.key});

  @override
  ConsumerState<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends ConsumerState<ActivationPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _machine = TextEditingController(text: '...');
  String? _machineId;
  String? _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    LicenseService.machineId().then((id) {
      if (mounted) {
        setState(() {
          _machineId = id;
          _machine.text = id;
        });
      }
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _machine.dispose();
    super.dispose();
  }

  Future<void> _renew() async {
    setState(() {
      _loading = true;
      _status = 'در حال اتصال به سرور...';
    });
    final message = await LicenseService.renewFromServer(_phone.text);
    if (!mounted) {
      return;
    }
    if (message != null) {
      setState(() {
        _loading = false;
        _status = message;
      });
      return;
    }
    ref.read(activationStateProvider.notifier).state = true;
    context.go(AppRoutes.login);
  }

  Future<void> _activateManual() async {
    setState(() => _loading = true);
    final error = await LicenseService.activate(_code.text);
    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() {
        _loading = false;
        _status = error;
      });
      return;
    }
    ref.read(activationStateProvider.notifier).state = true;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFF), AppColors.voidBg, Color(0xFFE6EFFA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.38),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppInfo.nameFa,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.cream),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Color.lerp(Colors.white, AppColors.primary, 0.08)!,
                            Color.lerp(Colors.white, AppColors.primary, 0.14)!,
                            Color.lerp(AppColors.primary, Colors.white, 0.88)!,
                          ],
                        ),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'تمدید / فعال‌سازی',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _status ?? 'برای شروع یا ادامه استفاده، از سرور تمدید کنید یا کد دستی وارد کنید.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.muted, height: 1.6),
                          ),
                          const SizedBox(height: 16),
                          const Text('شناسه دستگاه', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextField(
                            readOnly: true,
                            controller: _machine,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.92),
                              suffixIcon: IconButton(
                                tooltip: 'کپی',
                                onPressed: _machineId == null
                                    ? null
                                    : () {
                                        Clipboard.setData(ClipboardData(text: _machineId!));
                                        setState(() => _status = 'شناسه دستگاه کپی شد.');
                                      },
                                icon: const Icon(Icons.copy_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'شماره موبایل (برای تمدید از سرور)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              hintText: '09123456789',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AppPrimaryButton(
                            label: 'تمدید از سرور',
                            loading: _loading,
                            icon: Icons.cloud_done_rounded,
                            onPressed: _loading ? null : _renew,
                          ),
                          const SizedBox(height: 18),
                          const Text('اگر اینترنت ندارید — کد دستی', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _code,
                            textCapitalization: TextCapitalization.characters,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: 'کد فعال‌سازی',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _loading ? null : _activateManual,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('فعال‌سازی با کد دستی'),
                          ),
                        ],
                      ),
                    ),
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
