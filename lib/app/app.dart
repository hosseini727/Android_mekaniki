import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import '../core/backup/backup_scheduler.dart';
import '../core/constants/app_info.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_support_footer.dart';
import 'di/providers.dart';
import 'router/app_router.dart';

class KargahYarApp extends ConsumerStatefulWidget {
  const KargahYarApp({super.key});

  @override
  ConsumerState<KargahYarApp> createState() => _KargahYarAppState();
}

class _KargahYarAppState extends ConsumerState<KargahYarApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateProvider.notifier).restoreIfNeeded();
      BackupScheduler.runAfterUiReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppInfo.nameFa,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR'), Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        PersianMaterialLocalizations.delegate,
        PersianCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Expanded(child: child ?? const SizedBox.shrink()),
              const Material(
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: AppSupportFooter(),
                ),
              ),
            ],
          ),
        );
      },
      routerConfig: router,
    );
  }
}
