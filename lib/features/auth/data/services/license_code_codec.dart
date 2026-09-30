import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// همان قالب کد دستی دسکتاپ: ARR-XXXX-XXXX-XXXX-XXXX-XXXX-XX
class LicenseCodeCodec {
  LicenseCodeCodec._();

  static const _issuerNationalId = 'Eh0079877508!!';
  static const _keySalt = 'AvizhehRial-Offline-License-2026-Key!v2#9f3a7c2e';
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _encodedLen = 26;

  static String? tryValidate(String code, String machineId) {
    final normalized = _normalize(code);
    if (normalized.length < _encodedLen) {
      return 'کد فعال‌سازی ناقص است. کل کد را با خط تیره‌ها کپی کنید.';
    }
    final raw = _decodeBase32(normalized.substring(0, _encodedLen));
    if (raw.length < 16) {
      return 'کد فعال‌سازی نامعتبر است.';
    }
    final payload = Uint8List.sublistView(raw, 0, 12);
    final sig = Uint8List.sublistView(raw, 12, 16);
    final expected = _hmac(payload).sublist(0, 4);
    if (!_bytesEqual(sig, expected)) {
      return 'امضای کد معتبر نیست. کد را دوباره از پشتیبانی بگیرید.';
    }

    final mid = _u32le(payload, 0);
    if (mid != hashMachine(machineId)) {
      return 'این کد برای این دستگاه صادر نشده است.';
    }

    final issuerTag = _u16le(
      sha256.convert(utf8.encode('issuer|${_digits(_issuerNationalId)}')).bytes,
      0,
    );
    if (_u16le(payload, 8) != issuerTag) {
      return 'این کد با صادرکننده معتبر سازگار نیست.';
    }

    final issuedDays = _u16le(payload, 6);
    final issued = DateTime.utc(2024, 1, 1).add(Duration(days: issuedDays));
    if (DateTime.now().toUtc().isAfter(issued.add(const Duration(days: 180)))) {
      return 'مهلت فعال‌سازی این کد گذشته است. کد جدید بگیرید.';
    }
    return null;
  }

  static int daysOf(String code) {
    final raw = _decodeBase32(_normalize(code).substring(0, _encodedLen));
    return _u16le(raw, 4);
  }

  static String serialOf(String code) {
    final raw = _decodeBase32(_normalize(code).substring(0, _encodedLen));
    final payload = Uint8List.sublistView(raw, 0, 12);
    return _hex(_hmac(payload).sublist(0, 8));
  }

  static int hashMachine(String machineId) {
    final hash = sha256.convert(utf8.encode(machineId.trim().toUpperCase())).bytes;
    return _u32le(hash, 0);
  }

  static List<int> _hmac(List<int> data) {
    final nid = _digits(_issuerNationalId);
    final key = sha256.convert(utf8.encode('$_keySalt|$nid')).bytes;
    return Hmac(sha256, key).convert(data).bytes;
  }

  static String _normalize(String code) {
    final chars = StringBuffer();
    for (final c in code.toUpperCase().codeUnits) {
      final ch = String.fromCharCode(c);
      if (_alphabet.contains(ch)) {
        chars.write(ch);
      }
    }
    var text = chars.toString();
    if (text.startsWith('ARR') && text.length >= _encodedLen + 3) {
      text = text.substring(3);
    }
    return text;
  }

  static Uint8List _decodeBase32(String text) {
    final out = <int>[];
    var buffer = 0;
    var bits = 0;
    for (final c in text.split('')) {
      final idx = _alphabet.indexOf(c);
      if (idx < 0) {
        continue;
      }
      buffer = (buffer << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.add((buffer >> bits) & 0xFF);
      }
    }
    return Uint8List.fromList(out);
  }

  static int _u16le(List<int> b, int o) => b[o] | (b[o + 1] << 8);

  static int _u32le(List<int> b, int o) =>
      b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);

  static String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
