import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../utils/shamsi_format.dart';
import 'database_backup_result.dart';

const _lastDbBackupKey = 'db_backup_last_at';
const _lastDbBackupPathKey = 'db_backup_last_path';
const _backupChannel = MethodChannel('ir.kargahyar.kargah_yar/backup');

Future<DatabaseBackupResult> backupDatabaseFile() async {
  try {
    final db = await AppDatabase.instance();
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');

    final sourcePath = await AppDatabase.databasePath();
    await AppDatabase.close();

    final now = DateTime.now();
    final fileName = '${ShamsiFormat.fileStampTime(now)}-kargah_yar.db';
    final folder = await _backupFolder();
    final backupPath = p.join(folder.path, fileName);

    await _copyDatabaseFiles(sourcePath, backupPath);

    String? publicFolder;
    if (Platform.isAndroid) {
      publicFolder = await _saveToDownloads(fileName, await File(backupPath).readAsBytes());
    }

    await AppDatabase.reopen();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastDbBackupKey, now.millisecondsSinceEpoch);
    await prefs.setString(_lastDbBackupPathKey, backupPath);

    return DatabaseBackupResult(
      filePath: backupPath,
      folderPath: publicFolder ?? folder.path,
    );
  } catch (error) {
    try {
      await AppDatabase.reopen();
    } catch (_) {}
    return DatabaseBackupResult(error: '$error');
  }
}

Future<DatabaseBackupResult> restoreDatabaseFile() async {
  try {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return const DatabaseBackupResult(cancelled: true);
    }

    final selectedPath = picked.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) {
      return const DatabaseBackupResult(error: 'فایل انتخاب‌شده در دسترس نیست.');
    }

    final source = File(selectedPath);
    if (!await source.exists()) {
      return const DatabaseBackupResult(error: 'فایل پیدا نشد.');
    }
    if (!await _isSqliteFile(source)) {
      return const DatabaseBackupResult(error: 'فایل انتخاب‌شده پایگاه داده معتبر نیست.');
    }

    final dbPath = await AppDatabase.databasePath();
    await AppDatabase.close();

    final safetyName = '${ShamsiFormat.fileStampTime(DateTime.now())}-before-restore.db';
    final safetyFolder = await _backupFolder();
    final safetyPath = p.join(safetyFolder.path, safetyName);
    if (await File(dbPath).exists()) {
      await _copyDatabaseFiles(dbPath, safetyPath);
    }

    await source.copy(dbPath);
    await _deleteSidecarFiles(dbPath);

    await AppDatabase.reopen();

    return DatabaseBackupResult(
      filePath: dbPath,
      folderPath: safetyPath,
    );
  } catch (error) {
    try {
      await AppDatabase.reopen();
    } catch (_) {}
    return DatabaseBackupResult(error: '$error');
  }
}

Future<DateTime?> lastDatabaseBackupAt() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getInt(_lastDbBackupKey);
  if (raw == null) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(raw);
}

Future<String?> databaseBackupFolderPath() async {
  if (Platform.isAndroid) {
    return 'Downloads / GearPilot';
  }
  try {
    return (await _backupFolder()).path;
  } catch (_) {
    return null;
  }
}

Future<Directory> _backupFolder() async {
  Directory? base;
  if (Platform.isAndroid) {
    base = await getExternalStorageDirectory();
  }
  base ??= await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(base.path, 'GearPilot', 'database'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<void> _copyDatabaseFiles(String sourcePath, String destPath) async {
  await File(sourcePath).copy(destPath);
  final wal = File('$sourcePath-wal');
  if (await wal.exists()) {
    await wal.copy('$destPath-wal');
  }
  final shm = File('$sourcePath-shm');
  if (await shm.exists()) {
    await shm.copy('$destPath-shm');
  }
}

Future<void> _deleteSidecarFiles(String dbPath) async {
  for (final suffix in ['-wal', '-shm']) {
    final sidecar = File('$dbPath$suffix');
    if (await sidecar.exists()) {
      await sidecar.delete();
    }
  }
}

Future<bool> _isSqliteFile(File file) async {
  final raf = await file.open();
  try {
    final bytes = await raf.read(16);
    if (bytes.length < 15) {
      return false;
    }
    return String.fromCharCodes(bytes.sublist(0, 15)) == 'SQLite format 3';
  } finally {
    await raf.close();
  }
}

Future<String?> _saveToDownloads(String name, Uint8List bytes) async {
  if (!Platform.isAndroid) {
    return null;
  }
  try {
    return await _backupChannel.invokeMethod<String>('saveDb', {
      'name': name,
      'bytes': bytes,
    });
  } catch (_) {
    return null;
  }
}
