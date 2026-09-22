import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/backup/database_backup.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/shamsi_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/shop_settings.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _shop = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  bool _backingUp = false;
  bool _restoring = false;
  DateTime? _lastDbBackup;
  String? _dbBackupFolder;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    final lastDb = await DatabaseBackup.lastBackupAt();
    final dbFolder = await DatabaseBackup.folderPath();
    if (!mounted) {
      return;
    }
    setState(() {
      _lastDbBackup = lastDb;
      _dbBackupFolder = dbFolder;
    });
  }

  void _invalidateAllData() {
    ref.invalidate(vehiclesProvider);
    ref.invalidate(jobsProvider);
    ref.invalidate(partsProvider);
    ref.invalidate(scheduleProvider);
    ref.invalidate(settingsProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(billsProvider);
    ref.invalidate(reportsProvider);
    ref.invalidate(dashboardSnapshotProvider);
  }

  Future<void> _backupDatabaseNow() async {
    setState(() => _backingUp = true);
    try {
      final result = await DatabaseBackup.backup();
      await _loadBackupInfo();
      if (!mounted) {
        return;
      }
      final message = result.unsupported
          ? 'بک‌آپ پایگاه داده روی مرورگر پشتیبانی نمی‌شود. از اپ گوشی استفاده کنید.'
          : result.error != null
              ? 'خطا در بک‌آپ: ${result.error}'
              : 'فایل پایگاه داده ذخیره شد.\n${result.folderPath ?? result.filePath}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _backingUp = false);
      }
    }
  }

  Future<void> _restoreDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بازیابی پایگاه داده'),
        content: const Text(
          'با بازیابی، همه داده‌های فعلی جایگزین می‌شوند.\n'
          'قبل از بازیابی، یک نسخه امنیتی از دیتابیس فعلی ذخیره می‌شود.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('بازیابی'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _restoring = true);
    try {
      final result = await DatabaseBackup.restore();
      if (!mounted) {
        return;
      }
      if (result.cancelled) {
        return;
      }
      if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('بازیابی انجام نشد: ${result.error}')),
        );
        return;
      }
      _invalidateAllData();
      setState(() => _loaded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('پایگاه داده با موفقیت بازیابی شد.')),
      );
    } finally {
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  @override
  void dispose() {
    _shop.dispose();
    _owner.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _hydrate(ShopSettings settings) async {
    if (_loaded) {
      return;
    }
    _shop.text = settings.shopName;
    _owner.text = settings.ownerName;
    _phone.text = settings.phone;
    _address.text = settings.address;
    _loaded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final settings = ShopSettings(
        shopName: _shop.text.trim(),
        ownerName: _owner.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );
      await ref.read(settingsRepositoryProvider).save(settings);
      ref.invalidate(settingsProvider);
      ref.read(authStateProvider.notifier).applySettings(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تنظیمات کارگاه ذخیره شد.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSettings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات کارگاه')),
      body: asyncSettings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('خطا در تنظیمات')),
        data: (settings) {
          _hydrate(settings);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const Text(
                'اطلاعات روی صورتحساب داخلی و داشبورد از اینجا می‌آید.',
                style: TextStyle(color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 18),
              TextField(controller: _shop, decoration: const InputDecoration(labelText: 'نام کارگاه')),
              const SizedBox(height: 12),
              TextField(controller: _owner, decoration: const InputDecoration(labelText: 'نام صاحب کارگاه')),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                decoration: const InputDecoration(labelText: 'موبایل'),
              ),
              const SizedBox(height: 12),
              TextField(controller: _address, decoration: const InputDecoration(labelText: 'آدرس')),
              const SizedBox(height: 22),
              AppPrimaryButton(label: 'ذخیره تنظیمات', loading: _saving, onPressed: _save),
              const SizedBox(height: 28),
              const Text(
                'بک‌آپ پایگاه داده',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'یک فایل واقعی از دیتابیس (.db) گرفته می‌شود تا بتوانی همه اطلاعات را کامل بازیابی کنی. بک‌آپ خودکار هر هفته یک‌بار انجام می‌شود.',
                style: TextStyle(color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lastDbBackup == null
                          ? 'هنوز بک‌آپ دیتابیس گرفته نشده.'
                          : 'آخرین بک‌آپ دیتابیس: ${ShamsiFormat.withTime(_lastDbBackup!)}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kIsWeb
                          ? 'روی مرورگر بک‌آپ واقعی دیتابیس پشتیبانی نمی‌شود.'
                          : 'محل فایل: ${_dbBackupFolder ?? 'Downloads / GearPilot'}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppPrimaryButton(
                label: 'بک‌آپ دیتابیس',
                loading: _backingUp,
                onPressed: _backupDatabaseNow,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _restoring ? null : _restoreDatabase,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cream,
                  side: const BorderSide(color: AppColors.line),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _restoring
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('بازیابی از فایل .db'),
              ),
            ],
          );
        },
      ),
    );
  }
}
