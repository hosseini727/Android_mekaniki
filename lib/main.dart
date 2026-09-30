import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/di/providers.dart';
import 'core/backup/backup_scheduler.dart';
import 'core/database/database_bootstrap.dart';
import 'features/auth/data/repositories/local_auth_repository.dart';
import 'features/auth/data/services/license_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapDatabase();
  await initializeDateFormatting('fa');
  await BackupScheduler.start();
  final activated = await LicenseService.isActivated();
  final authRepo = LocalAuthRepository();
  await authRepo.restoreSession();
  runApp(
    ProviderScope(
      overrides: [
        activationStateProvider.overrideWith((ref) => activated),
        authRepositoryProvider.overrideWith((ref) => authRepo),
      ],
      child: const KargahYarApp(),
    ),
  );
}
