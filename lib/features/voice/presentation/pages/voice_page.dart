import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/workshop_speech.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../visits/domain/repositories/visit_repository.dart';
import '../../../visits/presentation/providers/visit_providers.dart';
import '../../domain/voice_parser.dart';

class VoicePage extends ConsumerStatefulWidget {
  const VoicePage({super.key, this.initialVehicleId});

  final int? initialVehicleId;

  @override
  ConsumerState<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends ConsumerState<VoicePage> {
  final _speech = SpeechToText();
  final _manual = TextEditingController();
  final _vehicleSearch = TextEditingController();
  VoiceParseResult? _parsed;
  List<Vehicle> _vehicles = [];
  int? _vehicleId;
  String _vehicleQuery = '';
  bool _vehicleSearchActive = false;
  bool _listening = false;
  bool _saving = false;
  String _committedText = '';
  String _listenBaseText = '';
  String _sessionBestText = '';
  bool _sessionCommitted = false;
  bool _ignoreSpeechResults = false;
  String _status = 'متن را بگو یا بنویس. مثلاً: شمع عوض شد چهار میلیون، اجرت هشتصد هزار';

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  String _digitsOnly(String value) {
    const map = {
      '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
      '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final mapped = map[char] ?? char;
      if (RegExp(r'[0-9]').hasMatch(mapped)) {
        buffer.write(mapped);
      }
    }
    return buffer.toString();
  }

  bool _vehicleMatches(Vehicle car, String needle) {
    if (needle.isEmpty) {
      return true;
    }
    final q = needle.trim();
    final digits = _digitsOnly(q);

    if (car.ownerName.contains(q)) {
      return true;
    }
    if (car.ownerPhone.contains(q)) {
      return true;
    }
    if (digits.isNotEmpty && _digitsOnly(car.ownerPhone).contains(digits)) {
      return true;
    }
    if (car.plate.display.contains(q)) {
      return true;
    }
    if (car.plateKey.contains(q)) {
      return true;
    }
    if (car.listLabel.contains(q)) {
      return true;
    }
    final plateDigits = _digitsOnly('${car.plate.display}${car.plateKey}');
    if (digits.isNotEmpty && plateDigits.contains(digits)) {
      return true;
    }
    return false;
  }

  String _vehicleDisplayLabel(Vehicle car) => '${car.plate.display}  ·  ${car.ownerPhone}';

  Vehicle? _selectedVehicle() {
    if (_vehicleId == null) {
      return null;
    }
    for (final car in _vehicles) {
      if (car.id == _vehicleId) {
        return car;
      }
    }
    return null;
  }

  void _applySelectedVehicleToField() {
    final car = _selectedVehicle();
    if (car == null) {
      _vehicleSearch.clear();
      return;
    }
    _vehicleSearch.value = TextEditingValue(
      text: _vehicleDisplayLabel(car),
      selection: TextSelection.collapsed(offset: _vehicleDisplayLabel(car).length),
    );
  }

  void _selectVehicle(Vehicle car) {
    setState(() {
      _vehicleId = car.id;
      _vehicleQuery = '';
      _vehicleSearchActive = false;
      _applySelectedVehicleToField();
    });
  }

  void _startVehicleSearch() {
    setState(() {
      _vehicleSearchActive = true;
      _vehicleQuery = '';
      _vehicleSearch.clear();
    });
  }

  static const _minVehicleSearchLength = 3;

  List<Vehicle> _searchResults() {
    final needle = _vehicleQuery.trim();
    if (!_vehicleSearchActive || needle.length < _minVehicleSearchLength) {
      return const [];
    }
    return _vehicles.where((car) => _vehicleMatches(car, needle)).toList();
  }

  void _onVehicleSearchChanged(String value) {
    setState(() {
      _vehicleSearchActive = true;
      _vehicleQuery = value;
    });
  }

  Future<void> _loadVehicles() async {
    final vehicles = await ref.read(vehicleRepositoryProvider).all();
    if (!mounted) {
      return;
    }
    setState(() {
      _vehicles = vehicles;
      final preset = widget.initialVehicleId;
      if (preset != null && vehicles.any((car) => car.id == preset)) {
        _vehicleId = preset;
      } else {
        _vehicleId = vehicles.isEmpty ? null : vehicles.first.id;
      }
      _vehicleSearchActive = false;
      _vehicleQuery = '';
      _applySelectedVehicleToField();
    });
  }

  @override
  void dispose() {
    _manual.dispose();
    _vehicleSearch.dispose();
    _speech.stop();
    super.dispose();
  }

  /// بعضی گوشی‌ها بین هر کلمه خط جدید یا + می‌گذارند
  String _flattenSpeech(String raw) {
    return raw
        .replaceAll('+', ' ')
        .replaceAll(RegExp(r'[\r\n\t|·•]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _dedupeSpeechText(String raw) {
    final flat = _flattenSpeech(raw);
    if (flat.length < 8) {
      return flat;
    }
    for (var i = 1; i < flat.length; i++) {
      if (flat[i] != ' ') {
        continue;
      }
      final first = flat.substring(0, i).trim();
      final second = flat.substring(i + 1).trim();
      if (first.isNotEmpty && first == second) {
        return first;
      }
    }
    return flat;
  }

  String _appendWithoutDuplicate(String base, String segment) {
    final left = _flattenSpeech(base);
    final right = _flattenSpeech(segment);
    if (right.isEmpty) {
      return left;
    }
    if (left.isEmpty) {
      return right;
    }
    if (left == right || left.endsWith(' $right')) {
      return left;
    }
    if ('$left $right' == '$right $right') {
      return right;
    }
    return '$left $right';
  }

  // فقط برای نتیجه صدا — متن را در کادر ست می‌کند
  String _combinedVoiceText() {
    final base = _dedupeSpeechText(_listenBaseText);
    final session = _dedupeSpeechText(_sessionBestText);
    if (session.isEmpty) {
      return base;
    }
    return _dedupeSpeechText(_appendWithoutDuplicate(base, session));
  }

  void _refreshVoiceDisplay() {
    final combined = _combinedVoiceText();
    if (combined.isEmpty) {
      return;
    }
    final parsed = VoiceParser.fromSpeech(combined);
    setState(() {
      _manual.value = TextEditingValue(
        text: combined,
        selection: TextSelection.collapsed(offset: combined.length),
      );
      _parsed = parsed;
      _status = parsed.hasAmount
          ? 'تشخیص داده شد. خودرو را انتخاب کن و ثبت کن.'
          : 'مبلغ پیدا نشد. متن را کامل‌تر بگو یا دستی درستش کن.';
    });
  }

  void _commitSessionToBase() {
    if (_sessionCommitted) {
      return;
    }
    final segment = _dedupeSpeechText(_sessionBestText);
    if (segment.isEmpty) {
      return;
    }
    _listenBaseText = _appendWithoutDuplicate(_listenBaseText, segment);
    _sessionBestText = '';
    _sessionCommitted = true;
  }

  bool _shouldKeepSessionText(String currentBest, String incoming) {
    if (incoming.length >= currentBest.length) {
      return true;
    }
    if (currentBest.startsWith(incoming)) {
      return false;
    }
    if (incoming.startsWith(currentBest)) {
      return true;
    }
    return false;
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    if (_ignoreSpeechResults) {
      return;
    }
    final text = _flattenSpeech(result.recognizedWords);
    if (text.isEmpty) {
      return;
    }

    if (result.finalResult) {
      if (_sessionBestText.isEmpty || _shouldKeepSessionText(_sessionBestText, text)) {
        _sessionBestText = text;
      }
      _refreshVoiceDisplay();
      return;
    }

    if (_sessionBestText.isEmpty || _shouldKeepSessionText(_sessionBestText, text)) {
      _sessionBestText = text;
    }
    _refreshVoiceDisplay();
  }

  // فقط برای تایپ دستی — فقط parse می‌کند، متن را دست نمی‌زند
  void _applyManualText(String value) {
    final parsed = value.trim().isEmpty ? null : VoiceParser.fromSpeech(value.trim());
    setState(() {
      _parsed = parsed;
      if (parsed == null) {
        _status = 'متن را بگو یا بنویس. مثلاً: شمع عوض شد چهار میلیون، اجرت هشتصد هزار';
      } else {
        _status = parsed.hasAmount
            ? 'تشخیص داده شد. خودرو را انتخاب کن و ثبت کن.'
            : 'مبلغ پیدا نشد. متن را کامل‌تر بگو یا دستی درستش کن.';
      }
    });
  }

  void _commitCurrentText() {
    _committedText = _dedupeSpeechText(_manual.text);
  }

  void _finishListening() {
    _ignoreSpeechResults = true;
    _commitSessionToBase();
    _refreshVoiceDisplay();
    _commitCurrentText();
    _sessionBestText = '';
    _listening = false;
  }

  void _clearText() {
    setState(() {
      _manual.clear();
      _committedText = '';
      _listenBaseText = '';
      _sessionBestText = '';
      _parsed = null;
      _status = 'متن پاک شد. دوباره بگو یا بنویس.';
    });
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      _finishListening();
      await _speech.stop();
      if (mounted) {
        setState(() {});
      }
      return;
    }
    _commitCurrentText();
    _listenBaseText = _committedText;
    _sessionBestText = '';
    _sessionCommitted = false;
    _ignoreSpeechResults = false;
    final ready = await WorkshopSpeech.ensureReady(
      _speech,
      onStatus: (status) {
        if (!mounted) {
          return;
        }
        if (status == 'done' || status == 'notListening') {
          if (mounted && _listening) {
            _finishListening();
            setState(() {});
          }
        }
      },
      onError: (message) {
        if (!mounted) {
          return;
        }
        setState(() {
          _listening = false;
          _status = message;
        });
      },
    );
    if (!mounted) {
      return;
    }
    if (!ready) {
      setState(() => _status = 'میکروفون روی این دستگاه فعال نشد. متن را دستی بنویس.');
      return;
    }
    setState(() {
      _listening = true;
      _status = 'گوش می‌دهم... کار و مبلغ را کامل بگو.';
    });
    try {
      final localeId = await WorkshopSpeech.persianLocale(_speech);
      await _speech.listen(
        listenOptions: WorkshopSpeech.listenOptions(localeId),
        onResult: _handleSpeechResult,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _listening = false;
          _status = 'تشخیص صدا روی این دستگاه کار نکرد. متن را دستی بنویس.';
        });
      }
    }
  }

  Future<void> _save() async {
    // اگر parse نشده ولی متن دستی هست، دوباره parse کن
    var parsed = _parsed;
    final manualText = _manual.text.trim();
    if (parsed == null && manualText.isNotEmpty) {
      parsed = VoiceParser.fromSpeech(manualText);
    }
    final vehicleId = _vehicleId;
    if (parsed == null || !parsed.hasAmount || vehicleId == null) {
      setState(() => _status = 'اول خودرو و مبلغ را مشخص کن.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(visitRepositoryProvider).save(
            VisitDraft(
              vehicleId: vehicleId,
              happenedAt: DateTime.now(),
              title: parsed.title,
              note: parsed.note,
              amount: parsed.amount,
              laborAmount: parsed.laborAmount,
              partsAmount: parsed.partsAmount,
            ),
          );
      ref.invalidate(vehicleDetailProvider(vehicleId));
      ref.invalidate(billsProvider);
      ref.invalidate(reportsProvider);
      ref.invalidate(customersProvider);
      ref.invalidate(dashboardSnapshotProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کار صوتی روی پرونده ماشین ثبت شد.')),
      );
      context.push(AppRoutes.vehicleHistoryPath(vehicleId));
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'ثبت نشد. دوباره تلاش کن.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(_status, style: const TextStyle(color: AppColors.muted, height: 1.7)),
        const SizedBox(height: 22),
        Center(
          child: Material(
            color: _listening ? AppColors.copper : AppColors.surfaceHigh,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggleListen,
              child: SizedBox(
                width: 76,
                height: 76,
                child: Icon(
                  _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  size: 30,
                  color: _listening ? AppColors.onPrimary : AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _listening ? 'برای توقف دوباره بزن' : 'برای شروع ضبط بزن',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _manual,
          minLines: 3,
          maxLines: 8,
          textAlign: TextAlign.start,
          textDirection: TextDirection.rtl,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(
            fontSize: 16,
            height: 1.7,
            fontFamily: 'Vazirmatn',
          ),
          decoration: const InputDecoration(
            labelText: 'متن تشخیص‌داده‌شده',
            hintText: 'شمع عوض شد چهار میلیون اجرت هشتصد هزار',
            alignLabelWithHint: true,
            isDense: false,
          ),
          onChanged: (value) {
            final flat = _flattenSpeech(value);
            if (value.contains(RegExp(r'[\r\n+]'))) {
              _manual.value = TextEditingValue(
                text: flat,
                selection: TextSelection.collapsed(offset: flat.length),
              );
            }
            if (!_listening) {
              _committedText = _dedupeSpeechText(flat);
            }
            _applyManualText(_dedupeSpeechText(flat));
          },
        ),
        if (_manual.text.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _clearText,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('پاک کردن متن', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.muted,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        const SizedBox(height: 14),
        if (_vehicles.isNotEmpty) ...[
          TextField(
            controller: _vehicleSearch,
            onTap: () {
              if (!_vehicleSearchActive) {
                _startVehicleSearch();
              }
            },
            onChanged: _onVehicleSearchChanged,
            decoration: InputDecoration(
              labelText: 'ثبت روی خودرو',
              hintText: _vehicleSearchActive
                  ? 'حداقل ۳ حرف: موبایل، پلاک، نام...'
                  : 'برای تغییر خودرو، اینجا بزنید',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _selectedVehicle() != null && !_vehicleSearchActive
                  ? IconButton(
                      tooltip: 'تغییر خودرو',
                      onPressed: _startVehicleSearch,
                      icon: const Icon(Icons.edit_rounded, size: 20),
                    )
                  : null,
            ),
          ),
          Builder(
            builder: (context) {
              if (!_vehicleSearchActive) {
                return const SizedBox.shrink();
              }
              final needle = _vehicleQuery.trim();
              if (needle.length < _minVehicleSearchLength) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'برای جستجو حداقل ۳ حرف بنویسید.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                );
              }
              final visible = _searchResults();
              if (visible.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'خودرویی با این مشخصات پیدا نشد.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final car = visible[index];
                      final selected = car.id == _vehicleId;
                      return Material(
                        color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _selectVehicle(car),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        car.plate.display,
                                        style: TextStyle(
                                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        car.ownerPhone,
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 13,
                                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ] else
          const Text('اول از پذیرش پلاک یک ماشین ثبت کن.', style: TextStyle(color: AppColors.muted)),
        if (parsed != null) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('پیش‌فاکتور تشخیص‌شده', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(parsed.title, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 12),
                ...parsed.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(line.isLabor ? 'اجرت' : line.label)),
                        Text(
                          MoneyFormat.toman(line.amount),
                          style: TextStyle(
                            color: line.isLabor ? AppColors.teal : AppColors.copper,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: AppColors.line),
                Row(
                  children: [
                    const Expanded(child: Text('جمع', style: TextStyle(fontWeight: FontWeight.w700))),
                    Text(
                      MoneyFormat.toman(parsed.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        AppPrimaryButton(
          label: 'ثبت فاکتور',
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
