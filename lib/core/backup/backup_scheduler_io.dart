import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../database/database_bootstrap.dart';
import 'database_backup.dart';

const _taskName = 'gear_pilot_weekly_db_backup';
const _uniqueName = 'gear-pilot-weekly-db-backup';
const _legacyDailyTask = 'gear-pilot-daily-db-backup';
const _legacyPdfTask = 'mechanic-yar-daily-pdf-backup';
const _backupInterval = Duration(days: 7);

@pragma('vm:entry-point')
void backupDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      await bootstrapDatabase();
      await _backupIfDue();
      return true;
    } catch (_) {
      return false;
    }
  });
}

class BackupScheduler {
  static Future<void> start() async {
    if (Platform.isAndroid) {
      try {
        await Workmanager().initialize(backupDispatcher);
        await Workmanager().cancelByUniqueName(_legacyPdfTask);
        await Workmanager().cancelByUniqueName(_legacyDailyTask);
        await Workmanager().registerPeriodicTask(
          _uniqueName,
          _taskName,
          frequency: _backupInterval,
          existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        );
      } catch (_) {}
    }
  }

  static Future<void> runAfterUiReady() async {
    await _backupIfDue();
  }
}

Future<void> _backupIfDue() async {
  final last = await DatabaseBackup.lastBackupAt();
  if (last != null && DateTime.now().difference(last) < _backupInterval) {
    return;
  }
  await DatabaseBackup.backup();
}
