import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kargah_yar/app/di/providers.dart';
import 'package:kargah_yar/app/router/app_routes.dart';
import 'package:kargah_yar/core/constants/app_info.dart';
import 'package:kargah_yar/core/constants/app_spacing.dart';
import 'package:kargah_yar/core/theme/app_colors.dart';
import 'package:kargah_yar/core/widgets/app_primary_button.dart';
import 'package:kargah_yar/features/auth/data/repositories/local_auth_repository.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _hasAccount = false;
  bool _checkingAccount = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAccountState());
  }

  Future<void> _loadAccountState() async {
    final repo = ref.read(authRepositoryProvider);
    final hasAccount = repo is LocalAuthRepository ? await repo.hasAccount() : false;
    final phone = repo is LocalAuthRepository ? await repo.savedPhone() : null;
    if (!mounted) {
      return;
    }
    if (phone != null && phone.isNotEmpty) {
      _phone.text = phone;
    }
    setState(() {
      _hasAccount = hasAccount;
      _checkingAccount = false;
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).login(
            phone: _phone.text,
            password: _password.text,
          );
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              1.28, 0, 0, 0, 36,
              0, 1.28, 0, 0, 36,
              0, 0, 1.28, 0, 36,
              0, 0, 0, 1, 0,
            ]),
            child: Image.asset(
              'assets/images/login_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.04),
                  AppColors.voidBg.withValues(alpha: 0.35),
                  AppColors.voidBg.withValues(alpha: 0.72),
                ],
                stops: const [0.0, 0.55, 0.92],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 74,
                        height: 74,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppInfo.nameFa,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppInfo.tagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _hasAccount ? 'ورود مکانیک' : 'راه‌اندازی کارگاه',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _checkingAccount
                                ? 'در حال بررسی...'
                                : _hasAccount
                                    ? 'با موبایل و رمز عبور کارگاه وارد شو.'
                                    : 'اولین بار است. موبایل و رمز عبور کارگاه را تعریف کن.',
                            style: const TextStyle(color: AppColors.muted, height: 1.6),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'موبایل کارگاه',
                              prefixIcon: Icon(Icons.phone_iphone_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 11) {
                                return 'شماره موبایل را کامل وارد کنید.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'رمز عبور',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 4) {
                                return 'رمز عبور باید حداقل ۴ رقم باشد.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppPrimaryButton(
                            label: _hasAccount ? 'ورود به کارگاه' : 'شروع کار',
                            loading: _loading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
