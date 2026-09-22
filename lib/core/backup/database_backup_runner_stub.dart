import 'database_backup_result.dart';

Future<DatabaseBackupResult> backupDatabaseFile() async {
  return const DatabaseBackupResult(unsupported: true);
}

Future<DatabaseBackupResult> restoreDatabaseFile() async {
  return const DatabaseBackupResult(unsupported: true);
}

Future<DateTime?> lastDatabaseBackupAt() async => null;

Future<String?> databaseBackupFolderPath() async => null;
