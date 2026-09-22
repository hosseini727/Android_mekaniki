import 'database_backup_result.dart';
import 'database_backup_runner_stub.dart'
    if (dart.library.io) 'database_backup_runner_io.dart';

export 'database_backup_result.dart';

class DatabaseBackup {
  static Future<DatabaseBackupResult> backup() => backupDatabaseFile();

  static Future<DatabaseBackupResult> restore() => restoreDatabaseFile();

  static Future<DateTime?> lastBackupAt() => lastDatabaseBackupAt();

  static Future<String?> folderPath() => databaseBackupFolderPath();
}
