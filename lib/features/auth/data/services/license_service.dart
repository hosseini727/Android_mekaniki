import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_info.dart';
import 'license_code_codec.dart';

class LicenseService {
  LicenseService._();

  static const _storage = FlutterSecureStorage();
  static const _channel = MethodChannel('ir.kargahyar/device');
  static const _machineKey = 'gearpilot_license_machine_v1';
  static const _startedKey = 'gearpilot_license_started_v1';
  static const _expiresKey = 'gearpilot_license_expires_v1';
  static const _lastSeenKey = 'gearpilot_license_seen_v1';
  static const _kindKey = 'gearpilot_license_kind_v1';
  static const _serialsKey = 'gearpilot_license_serials_v1';

  static Future<bool> isActivated() async {
    final expires = _parseDate(await _storage.read(key: _expiresKey));
    final lastSeen = _parseDate(await _storage.read(key: _lastSeenKey));
    final kind = await _storage.read(key: _kindKey);
    if (expires == null || lastSeen == null || kind == null || kind == 'Pending') {
      return false;
    }

    final today = _today();
    if (today.isBefore(lastSeen.subtract(const Duration(days: 1)))) {
      return false;
    }
    if (today.isAfter(expires)) {
      return false;
    }
    if (today.isAfter(lastSeen)) {
      await _storage.write(key: _lastSeenKey, value: _format(today));
    }
    return true;
  }

  static Future<String> machineId() async {
    final cached = await _storage.read(key: _machineKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    var raw = '';
    try {
      raw = await _channel.invokeMethod<String>('androidId') ?? '';
    } catch (_) {}
    if (raw.trim().isEmpty) {
      raw = 'gear-${DateTime.now().microsecondsSinceEpoch}';
    }
    final hex = sha256.convert(utf8.encode(raw)).toString().toUpperCase();
    final id = '${hex.substring(0, 4)}-${hex.substring(4, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}';
    await _storage.write(key: _machineKey, value: id);
    return id;
  }

  /// null یعنی تمدید ذخیره شد.
  static Future<String?> renewFromServer(String phone) async {
    final normalized = _normalizePhone(phone);
    if (normalized == null) {
      return 'شماره موبایل را به صورت ۱۱ رقمی با ۰۹ وارد کنید.';
    }

    final id = await machineId();
    try {
      final response = await http
          .post(
            Uri.parse('${AppInfo.licenseServerUrl}/api/v1/license/renew'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'machineId': id,
              'productId': AppInfo.licenseProductId,
              'productName': AppInfo.licenseProductName,
              'version': AppInfo.version,
              'phone': normalized,
            }),
          )
          .timeout(const Duration(seconds: 20));

      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {}

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = body?['message'] as String?;
        return (message != null && message.isNotEmpty)
            ? message
            : 'سرور پاسخ نامعتبر داد (${response.statusCode}).';
      }
      if (body == null) {
        return 'پاسخ سرور قابل خواندن نیست.';
      }

      final status = (body['status'] as String? ?? '').trim().toLowerCase();
      final message = (body['message'] as String? ?? '').trim();
      if (status == 'active') {
        final expiresRaw = body['expiresAt'] as String?;
        final expires = _parseDate(expiresRaw);
        if (expires != null) {
          return _applyExactExpiry(expires, 'Server');
        }
        final code = body['activationCode'] as String?;
        if (code != null && code.isNotEmpty) {
          final manual = await activate(code);
          return manual;
        }
        return 'سرور مجوز فعال برگرداند ولی تاریخ انقضا نداشت.';
      }
      if (status == 'pending' || status == 'denied' || status == 'expired') {
        return message.isNotEmpty ? message : 'درخواست هنوز تأیید نشده است.';
      }
      return message.isNotEmpty ? message : 'تمدید از سرور ناموفق بود.';
    } on Exception {
      return 'اتصال به سرور برقرار نشد. اینترنت را بررسی کنید یا کد دستی وارد کنید.';
    }
  }

  static Future<String?> activate(String rawCode) async {
    final id = await machineId();
    final error = LicenseCodeCodec.tryValidate(rawCode, id);
    if (error != null) {
      return error;
    }
    final serial = LicenseCodeCodec.serialOf(rawCode);
    final used = await _usedSerials();
    if (used.contains(serial)) {
      return 'این تمدید قبلاً روی این دستگاه اعمال شده است.';
    }
    final days = LicenseCodeCodec.daysOf(rawCode);
    final today = _today();
    final current = _parseDate(await _storage.read(key: _expiresKey));
    final base = current != null && !current.isBefore(today) ? current : today;
    final expires = base.add(Duration(days: days));
    final started = _parseDate(await _storage.read(key: _startedKey)) ?? today;
    used.add(serial);
    await _writeState(started: started, expires: expires, kind: 'Activated', serials: used);
    return null;
  }

  static Future<String?> _applyExactExpiry(DateTime expires, String kind) async {
    final today = _today();
    if (expires.isBefore(today)) {
      return 'تاریخ انقضای دریافتی از سرور گذشته است.';
    }
    final started = _parseDate(await _storage.read(key: _startedKey)) ?? today;
    await _writeState(started: started, expires: expires, kind: kind, serials: await _usedSerials());
    return null;
  }

  static Future<void> _writeState({
    required DateTime started,
    required DateTime expires,
    required String kind,
    required Set<String> serials,
  }) async {
    final today = _today();
    await _storage.write(key: _startedKey, value: _format(started));
    await _storage.write(key: _expiresKey, value: _format(expires));
    await _storage.write(key: _lastSeenKey, value: _format(today));
    await _storage.write(key: _kindKey, value: kind);
    await _storage.write(key: _serialsKey, value: serials.join(','));
  }

  static Future<Set<String>> _usedSerials() async {
    final raw = await _storage.read(key: _serialsKey) ?? '';
    return raw.split(',').where((s) => s.isNotEmpty).toSet();
  }

  static String? _normalizePhone(String phone) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    final mapped = phone.split('').map((ch) {
      final faIndex = fa.indexOf(ch);
      if (faIndex >= 0) {
        return '$faIndex';
      }
      final arIndex = ar.indexOf(ch);
      if (arIndex >= 0) {
        return '$arIndex';
      }
      return ch;
    }).join();
    var digits = mapped.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0098') && digits.length >= 14) {
      digits = '0${digits.substring(4)}';
    } else if (digits.startsWith('98') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    } else if (digits.length == 10 && digits.startsWith('9')) {
      digits = '0$digits';
    }
    if (digits.length == 11 && digits.startsWith('09')) {
      return digits;
    }
    return null;
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.length < 10) {
      return null;
    }
    final parts = raw.substring(0, 10).split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  static String _format(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
