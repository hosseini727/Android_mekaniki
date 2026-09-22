import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OfflineActivationService {
  OfflineActivationService._();

  static const _storage = FlutterSecureStorage();
  static const _activeKey = 'gearpilot_activation_ok_v1';
  static const _codeKey = 'gearpilot_activation_code_v1';
  static const _activatedAtKey = 'gearpilot_activation_at_v1';
  static const _validFor = Duration(days: 90);

  static Future<bool> isActivated() async {
    final value = await _storage.read(key: _activeKey);
    if (value != '1') {
      return false;
    }
    final rawActivatedAt = await _storage.read(key: _activatedAtKey);
    final activatedAtMs = int.tryParse(rawActivatedAt ?? '');
    if (activatedAtMs == null) {
      await deactivate();
      return false;
    }
    final activatedAt = DateTime.fromMillisecondsSinceEpoch(activatedAtMs);
    final expiresAt = activatedAt.add(_validFor);
    if (DateTime.now().isAfter(expiresAt)) {
      await deactivate();
      return false;
    }
    return true;
  }

  static Future<bool> activate(String rawCode) async {
    final code = _normalize(rawCode);
    if (!_validCodes().contains(code)) {
      return false;
    }
    await _storage.write(key: _activeKey, value: '1');
    await _storage.write(key: _codeKey, value: code);
    await _storage.write(
      key: _activatedAtKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    return true;
  }

  static Future<void> deactivate() async {
    await _storage.delete(key: _activeKey);
    await _storage.delete(key: _codeKey);
    await _storage.delete(key: _activatedAtKey);
  }

  static String _normalize(String input) {
    return input.trim().toUpperCase().replaceAll(' ', '');
  }

  static Set<String> _validCodes() {
    final result = <String>{};
    for (var i = 1; i <= 200; i++) {
      final checksum = ((i * 73 + 19) % 900) + 100;
      result.add('GP-${i.toString().padLeft(4, '0')}-$checksum');
    }
    return result;
  }
}
