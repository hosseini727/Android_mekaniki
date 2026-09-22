import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/mechanic_account.dart';
import '../../domain/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository();

  static const _storage = FlutterSecureStorage();
  static const _phoneKey = 'auth_phone';
  static const _passwordKey = 'auth_password';
  static const _sessionExpiresKey = 'auth_session_expires_v1';
  static const _sessionDuration = Duration(hours: 24);

  MechanicAccount? _account;

  @override
  MechanicAccount? get currentAccount => _account;

  Future<String?> _readPassword() async {
    final secure = await _storage.read(key: _passwordKey);
    if (secure != null && secure.isNotEmpty) {
      return secure;
    }
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_passwordKey);
    if (legacy == null || legacy.isEmpty) {
      return null;
    }
    await _storage.write(key: _passwordKey, value: legacy);
    await prefs.remove(_passwordKey);
    return legacy;
  }

  Future<bool> hasAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_phoneKey);
    final password = await _readPassword();
    return phone != null && phone.isNotEmpty && password != null && password.isNotEmpty;
  }

  Future<String?> savedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  Future<bool> restoreSession() async {
    final expiresRaw = await _storage.read(key: _sessionExpiresKey);
    final expiresMs = int.tryParse(expiresRaw ?? '');
    if (expiresMs == null) {
      return false;
    }
    if (DateTime.now().millisecondsSinceEpoch >= expiresMs) {
      await _clearSession();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_phoneKey);
    if (phone == null || phone.isEmpty) {
      await _clearSession();
      return false;
    }

    _account = MechanicAccount(
      shopName: '',
      ownerName: '',
      phone: phone,
    );
    return true;
  }

  @override
  Future<MechanicAccount> login({
    required String phone,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final normalizedPhone = phone.trim();
    if (normalizedPhone.length < 11) {
      throw AuthFailure('شماره موبایل را کامل وارد کنید.');
    }
    if (password.length < 4) {
      throw AuthFailure('رمز عبور باید حداقل ۴ رقم باشد.');
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString(_phoneKey);
    final savedPassword = await _readPassword();

    if (savedPhone == null || savedPassword == null) {
      await prefs.setString(_phoneKey, normalizedPhone);
      await _storage.write(key: _passwordKey, value: password);
    } else if (normalizedPhone != savedPhone || password != savedPassword) {
      throw AuthFailure('موبایل یا رمز عبور اشتباه است.');
    }

    _account = MechanicAccount(
      shopName: '',
      ownerName: '',
      phone: normalizedPhone,
    );
    await _saveSession();
    return _account!;
  }

  @override
  Future<void> logout() async {
    _account = null;
    await _clearSession();
  }

  Future<void> _saveSession() async {
    final expiresAt = DateTime.now().add(_sessionDuration).millisecondsSinceEpoch;
    await _storage.write(key: _sessionExpiresKey, value: expiresAt.toString());
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: _sessionExpiresKey);
  }
}

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
