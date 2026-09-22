import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import 'package:url_launcher/url_launcher.dart';



import '../../../../app/di/providers.dart';

import '../../../../app/router/app_routes.dart';

import '../../../../core/constants/app_info.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../core/widgets/app_primary_button.dart';

import '../../data/services/offline_activation_service.dart';



class ActivationPage extends ConsumerStatefulWidget {

  const ActivationPage({super.key});



  @override

  ConsumerState<ActivationPage> createState() => _ActivationPageState();

}



class _ActivationPageState extends ConsumerState<ActivationPage> {

  final _code = TextEditingController();

  bool _loading = false;



  @override

  void dispose() {

    _code.dispose();

    super.dispose();

  }



  Future<void> _submit() async {

    setState(() => _loading = true);

    try {

      final ok = await OfflineActivationService.activate(_code.text);

      if (!mounted) {

        return;

      }

      if (!ok) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('کد فعال‌سازی معتبر نیست.')),

        );

        return;

      }

      ref.read(activationStateProvider.notifier).state = true;

      context.go(AppRoutes.login);

    } finally {

      if (mounted) {

        setState(() => _loading = false);

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

            colors: [

              Color(0xFFF7FAFF),

              AppColors.voidBg,

              Color(0xFFE6EFFA),

            ],

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

                      child: ClipOval(

                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),

                      ),

                    ),

                    const SizedBox(height: 16),

                    Text(

                      AppInfo.nameFa,

                      style: const TextStyle(

                        fontSize: 26,

                        fontWeight: FontWeight.w800,

                        color: AppColors.cream,

                      ),

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

                          stops: const [0.0, 0.5, 1.0],

                        ),

                        border: Border(

                          top: BorderSide(color: Colors.white.withValues(alpha: 0.95), width: 1.5),

                          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.18)),

                          left: BorderSide(color: Colors.white.withValues(alpha: 0.7)),

                          right: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),

                        ),

                        boxShadow: [

                          BoxShadow(

                            color: AppColors.primary.withValues(alpha: 0.22),

                            blurRadius: 24,

                            offset: const Offset(0, 12),

                          ),

                          BoxShadow(

                            color: Colors.black.withValues(alpha: 0.05),

                            blurRadius: 8,

                            offset: const Offset(0, 4),

                          ),

                        ],

                      ),

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.stretch,

                        children: [

                          const Text(

                            'فعال‌سازی برنامه',

                            textAlign: TextAlign.center,

                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),

                          ),

                          const SizedBox(height: 8),

                          const Text(

                            'برای ورود، کد فعال‌سازی مشتری را وارد کنید.',

                            textAlign: TextAlign.center,

                            style: TextStyle(color: AppColors.muted, height: 1.6),

                          ),

                          const SizedBox(height: 6),

                          Container(

                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                            decoration: BoxDecoration(

                              color: AppColors.primarySoft,

                              borderRadius: BorderRadius.circular(20),

                            ),

                            child: const Text(

                              'اعتبار هر کد: ۳ ماه',

                              textAlign: TextAlign.center,

                              style: TextStyle(

                                color: AppColors.primaryDark,

                                fontWeight: FontWeight.w700,

                                fontSize: 13,

                              ),

                            ),

                          ),

                          const SizedBox(height: 18),

                          TextField(

                            controller: _code,

                            textCapitalization: TextCapitalization.characters,

                            inputFormatters: [

                              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]')),

                            ],

                            decoration: InputDecoration(

                              labelText: 'کد فعال‌سازی',

                              hintText: 'مثال: GP-0001-192',

                              filled: true,

                              fillColor: Colors.white.withValues(alpha: 0.92),

                            ),

                          ),

                          const SizedBox(height: 14),

                          Material(

                            color: Colors.transparent,

                            child: InkWell(

                              onTap: () => launchUrl(Uri.parse('tel:${AppInfo.developerPhone}')),

                              borderRadius: BorderRadius.circular(16),

                              child: Ink(

                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

                                decoration: BoxDecoration(

                                  gradient: LinearGradient(

                                    begin: Alignment.topCenter,

                                    end: Alignment.bottomCenter,

                                    colors: [

                                      Colors.white.withValues(alpha: 0.95),

                                      AppColors.navBarBottom,

                                    ],

                                  ),

                                  borderRadius: BorderRadius.circular(16),

                                  border: Border.all(color: AppColors.line),

                                  boxShadow: [

                                    BoxShadow(

                                      color: AppColors.primary.withValues(alpha: 0.10),

                                      blurRadius: 10,

                                      offset: const Offset(0, 4),

                                    ),

                                  ],

                                ),

                                child: Row(

                                  children: [

                                    Container(

                                      width: 42,

                                      height: 42,

                                      decoration: BoxDecoration(

                                        shape: BoxShape.circle,

                                        gradient: const LinearGradient(

                                          colors: [AppColors.primary, AppColors.primaryDark],

                                        ),

                                        boxShadow: [

                                          BoxShadow(

                                            color: AppColors.primary.withValues(alpha: 0.30),

                                            blurRadius: 8,

                                            offset: const Offset(0, 3),

                                          ),

                                        ],

                                      ),

                                      child: const Icon(

                                        Icons.phone_in_talk_rounded,

                                        color: AppColors.onPrimary,

                                        size: 22,

                                      ),

                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(

                                      child: Column(

                                        crossAxisAlignment: CrossAxisAlignment.start,

                                        children: [

                                          const Text(

                                            'دریافت کد فعال‌سازی',

                                            style: TextStyle(

                                              fontWeight: FontWeight.w700,

                                              fontSize: 13,

                                            ),

                                          ),

                                          const SizedBox(height: 2),

                                          Text(

                                            AppInfo.developerPhone,

                                            style: const TextStyle(

                                              color: AppColors.primaryDark,

                                              fontWeight: FontWeight.w800,

                                              fontSize: 16,

                                            ),

                                          ),

                                        ],

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                            ),

                          ),

                          const SizedBox(height: 18),

                          AppPrimaryButton(

                            label: 'فعال‌سازی',

                            loading: _loading,

                            icon: Icons.verified_rounded,

                            onPressed: _submit,

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

