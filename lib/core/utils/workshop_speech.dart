import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class WorkshopSpeech {
  WorkshopSpeech._();

  static SpeechListenOptions listenOptions(String localeId) {
    return SpeechListenOptions(
      localeId: localeId,
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.dictation,
      listenFor: const Duration(seconds: 120),
      pauseFor: const Duration(seconds: 15),
    );
  }

  static Future<bool> ensureReady(
    SpeechToText speech, {
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  }) async {
    if (speech.isAvailable) {
      return true;
    }
    return speech.initialize(
      onStatus: onStatus,
      onError: (error) => onError(_messageFor(error.errorMsg)),
    );
  }

  static Future<String> persianLocale(SpeechToText speech) async {
    try {
      final locales = await speech.locales();
      for (final locale in locales) {
        final id = locale.localeId.toLowerCase();
        if (id.startsWith('fa')) {
          return _forPlatform(locale.localeId);
        }
      }
    } catch (_) {}
    return _forPlatform('fa_IR');
  }

  static String _forPlatform(String localeId) {
    final compact = localeId.replaceAll('-', '_');
    if (kIsWeb) {
      return compact.replaceAll('_', '-');
    }
    return compact;
  }

  static String _messageFor(String code) {
    final normalized = code.toLowerCase().replaceAll('-', '_');
    return switch (normalized) {
      'error_permission' ||
      'error_audio' ||
      'not_allowed' ||
      'service_not_allowed' ||
      'audio_capture' =>
        'اجازه میکروفون داده نشد. از تنظیمات گوشی یا مرورگر فعالش کن.',
      'error_network' || 'error_network_timeout' || 'network' =>
        'برای تشخیص صدا اینترنت لازم است. اتصال را چک کن.',
      'error_speech_timeout' || 'error_no_match' || 'no_speech' || 'no_match' =>
        'چیزی نشنیدم. دکمه میکروفون را بزن و دوباره بگو.',
      'error_language_not_supported' ||
      'error_language_unavailable' ||
      'language_not_supported' =>
        'زبان فارسی روی این دستگاه برای صدا فعال نیست. متن را دستی بنویس.',
      'error_busy' || 'aborted' => 'میکروفون مشغول است. چند ثانیه بعد دوباره بزن.',
      _ => 'تشخیص صدا انجام نشد. دوباره بگو یا متن را دستی بنویس.',
    };
  }
}
