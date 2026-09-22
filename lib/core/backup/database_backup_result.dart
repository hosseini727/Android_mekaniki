class DatabaseBackupResult {
  const DatabaseBackupResult({
    this.filePath,
    this.folderPath,
    this.unsupported = false,
    this.cancelled = false,
    this.error,
  });

  final String? filePath;
  final String? folderPath;
  final bool unsupported;
  final bool cancelled;
  final String? error;

  bool get ok => error == null && !unsupported && !cancelled && filePath != null;
}
