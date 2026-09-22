import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:kargah_yar/app/di/providers.dart';
import 'package:kargah_yar/app/router/app_routes.dart';
import 'package:kargah_yar/core/theme/app_colors.dart';
import 'package:kargah_yar/core/utils/workshop_speech.dart';
import 'package:kargah_yar/core/widgets/app_primary_button.dart';
import 'package:kargah_yar/features/vehicles/domain/entities/vehicle.dart';
import 'package:kargah_yar/features/vehicles/domain/plate_speech_parser.dart';
import 'package:kargah_yar/features/vehicles/presentation/widgets/iran_plate_field.dart';

class IntakePage extends ConsumerStatefulWidget {
  const IntakePage({super.key});

  @override
  ConsumerState<IntakePage> createState() => _IntakePageState();
}

class _IntakePageState extends ConsumerState<IntakePage> {
  final _speech = SpeechToText();
  IranPlate _plate = IranPlate.empty();
  bool _busy = false;
  bool _listening = false;
  String? _hint;

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _listenPlate() async {
    if (_busy) {
      return;
    }
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _listening = false);
      }
      return;
    }
    final ready = await WorkshopSpeech.ensureReady(
      _speech,
      onStatus: (status) {
        if (!mounted) {
          return;
        }
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (message) {
        if (!mounted) {
          return;
        }
        setState(() {
          _listening = false;
          _hint = message;
        });
      },
    );
    if (!mounted) {
      return;
    }
    if (!ready) {
      setState(() => _hint = 'میکروفون روی این دستگاه فعال نشد. پلاک را دستی وارد کن.');
      return;
    }
    final localeId = await WorkshopSpeech.persianLocale(_speech);
    if (!mounted) {
      return;
    }
    setState(() {
      _listening = true;
      _hint = 'پلاک را بگو. مثلاً: دوازده ب سیصد چهل پنج بیست و دو';
    });
    try {
      await _speech.listen(
        listenOptions: WorkshopSpeech.listenOptions(localeId),
        onResult: (result) {
          final text = result.recognizedWords.trim();
          if (text.isEmpty) {
            return;
          }
          final parsed = PlateSpeechParser.fromSpeech(text);
          if (!mounted) {
            return;
          }
          setState(() {
            _hint = 'شنیدم: $text';
            if (parsed != null) {
              _plate = parsed;
            }
          });
          if (result.finalResult) {
            _speech.stop();
            if (parsed != null && parsed.isComplete) {
              _search();
            } else if (mounted) {
              setState(() {
                _listening = false;
                _hint = parsed == null
                    ? 'شنیدم «$text» ولی پلاک کامل نبود. آرام‌تر بگو یا دستی درست کن.'
                    : 'پلاک ناقص است. بقیه را دستی کامل کن یا دوباره بگو.';
              });
            }
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _listening = false;
          _hint = 'تشخیص صدا روی این دستگاه کار نکرد. پلاک را دستی وارد کن.';
        });
      }
    }
  }

  Future<void> _search() async {
    if (!_plate.isComplete) {
      setState(() => _hint = 'پلاک را کامل وارد کن.');
      return;
    }
    setState(() {
      _busy = true;
      _hint = null;
    });
    try {
      final vehicle = await ref.read(vehicleRepositoryProvider).findByPlate(_plate.key);
      if (!mounted) {
        return;
      }
      if (vehicle == null) {
        context.push(AppRoutes.vehicleNewPath(_plate.key));
        return;
      }
      context.push(AppRoutes.vehicleHistoryPath(vehicle.id));
    } catch (_) {
      if (mounted) {
        setState(() => _hint = 'جستجو انجام نشد. دوباره تلاش کن.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const Text(
          'پذیرش خودرو',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'پلاک را دستی وارد کن یا با صدا بگو. اگر ماشین قبلاً آمده باشد تاریخچه‌اش باز می‌شود.',
          style: TextStyle(color: AppColors.muted, height: 1.7),
        ),
        const SizedBox(height: 22),
        IranPlateField(
          value: _plate,
          onChanged: (value) => setState(() => _plate = value),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _busy ? null : _listenPlate,
          icon: Icon(_listening ? Icons.mic_rounded : Icons.mic_none_rounded),
          label: Text(_listening ? 'دارم گوش می‌دهم... دوباره بزن تا بایستد' : 'گفتن پلاک'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _listening ? AppColors.copper : AppColors.cream,
            side: BorderSide(color: _listening ? AppColors.copper : AppColors.line),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        AppPrimaryButton(
          label: 'جستجو در کارگاه',
          loading: _busy,
          onPressed: _search,
        ),
        if (_hint != null) ...[
          const SizedBox(height: 14),
          Text(_hint!, style: const TextStyle(color: AppColors.muted)),
        ],
      ],
    );
  }
}
