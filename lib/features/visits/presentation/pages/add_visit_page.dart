import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../app/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/toman_input_formatter.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../parts/domain/entities/part_item.dart';
import '../../domain/constants/common_job_titles.dart';
import '../../domain/entities/service_visit.dart';
import '../../domain/repositories/visit_repository.dart';
import '../providers/visit_providers.dart';

class AddVisitPage extends ConsumerStatefulWidget {
  const AddVisitPage({super.key, required this.vehicleId, this.visitId});

  final int vehicleId;
  final int? visitId;

  @override
  ConsumerState<AddVisitPage> createState() => _AddVisitPageState();
}

class _SelectedPart {
  _SelectedPart({required this.item, this.qty = 1, int? unitPrice})
      : unitPrice = unitPrice ?? item.sellPrice,
        price = TextEditingController(
          text: TomanInputFormatter.formatInt(unitPrice ?? item.sellPrice),
        );

  final PartItem item;
  int qty;
  int unitPrice;
  final TextEditingController price;

  int get total => qty * unitPrice;

  void dispose() => price.dispose();
}

class _AddVisitPageState extends ConsumerState<AddVisitPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _labor = TextEditingController();
  DateTime _date = DateTime.now();
  bool _paid = false;
  bool _saving = false;
  String? _selectedQuickTitle;
  final _selectedParts = <_SelectedPart>[];
  bool _hydrated = false;

  final _speech = stt.SpeechToText();
  bool _listening = false;

  bool get _isEditing => widget.visitId != null;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _labor.dispose();
    for (final part in _selectedParts) {
      part.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleVoiceNote() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      onError: (_) => setState(() => _listening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
    );
    if (!available || !mounted) return;
    setState(() => _listening = true);
    await _speech.listen(
      localeId: 'fa_IR',
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            setState(() {
              final current = _note.text;
              _note.text = current.isEmpty ? text : '$current $text';
              _note.selection = TextSelection.collapsed(offset: _note.text.length);
            });
          }
          setState(() => _listening = false);
        }
      },
    );
  }

  int _parseAmount(String raw) => TomanInputFormatter.parse(raw);

  int get _laborAmount => _parseAmount(_labor.text);

  int get _partsAmount => _selectedParts.fold<int>(0, (sum, item) => sum + item.total);

  int get _totalAmount => _laborAmount + _partsAmount;

  void _removePart(int index) {
    setState(() => _selectedParts.removeAt(index).dispose());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اجرت یا حداقل یک قطعه را وارد کنید.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final draft = VisitDraft(
        vehicleId: widget.vehicleId,
        happenedAt: _isEditing ? _date : DateTime.now(),
        title: _title.text.trim(),
        note: _note.text.trim(),
        amount: _totalAmount,
        laborAmount: _laborAmount,
        partsAmount: _partsAmount,
        paid: _paid,
        partLines: _selectedParts
            .map(
              (part) => VisitPartLine(
                partId: part.item.id > 0 ? part.item.id : null,
                name: part.item.name,
                qty: part.qty,
                unitPrice: part.unitPrice,
              ),
            )
            .toList(),
      );
      final repo = ref.read(visitRepositoryProvider);
      if (_isEditing) {
        await repo.update(widget.visitId!, draft);
      } else {
        await repo.save(draft);
      }
      ref.invalidate(vehicleDetailProvider(widget.vehicleId));
      ref.invalidate(billsProvider);
      ref.invalidate(reportsProvider);
      ref.invalidate(partsProvider);
      ref.invalidate(customersProvider);
      ref.invalidate(dashboardSnapshotProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'صورتحساب ویرایش شد.' : 'کار با موفقیت ثبت شد.')),
      );
      context.pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ثبت انجام نشد. دوباره تلاش کن.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  List<String> _titleOptions(List<PartItem> inventory) {
    final titles = <String>{
      ...defaultCarPartTitles,
      ...commonJobTitles,
      ...inventory.map((item) => item.name),
      if (_title.text.trim().isNotEmpty) _title.text.trim(),
    };
    final list = titles.toList()..sort();
    return list;
  }

  Future<void> _defineNewTitle() async {
    final name = TextEditingController();
    final sell = TextEditingController();
    final stock = TextEditingController(text: '1');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('قطعه یا عنوان جدید', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 14),
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'نام قطعه / عنوان کار'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sell,
                keyboardType: TextInputType.number,
                inputFormatters: [TomanInputFormatter()],
                decoration: const InputDecoration(labelText: 'قیمت فروش (اختیاری)', suffixText: 'تومان'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stock,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'موجودی انبار'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ذخیره قطعه', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    final title = name.text.trim();
    final sellPrice = TomanInputFormatter.parse(sell.text);
    final stockQty = int.tryParse(stock.text) ?? 0;
    name.dispose();
    sell.dispose();
    stock.dispose();
    if (saved != true || title.isEmpty || !mounted) {
      return;
    }
    final created = await ref.read(partRepositoryProvider).save(
          PartDraft(
            name: title,
            sku: '',
            stock: stockQty,
            buyPrice: 0,
            sellPrice: sellPrice,
          ),
        );
    ref.invalidate(partsProvider);
    setState(() {
      _title.text = created.name;
      _selectedQuickTitle = null;
    });
  }

  void _hydrateIfNeeded(VehicleDetail detail, List<PartItem> inventory) {
    if (_hydrated || widget.visitId == null) {
      return;
    }
    final visit = detail.visits.where((item) => item.id == widget.visitId).firstOrNull;
    if (visit == null) {
      return;
    }
    _hydrated = true;
    _title.text = visit.title;
    _note.text = visit.note;
    _labor.text = TomanInputFormatter.formatInt(visit.laborAmount);
    _date = visit.happenedAt;
    _paid = visit.paid;
    _selectedQuickTitle = null;
    for (final part in _selectedParts) {
      part.dispose();
    }
    _selectedParts
      ..clear()
      ..addAll(
        visit.partLines.map((line) {
          final item = inventory.where((part) => part.id == line.partId).firstOrNull ??
              PartItem(
                id: line.partId ?? 0,
                name: line.name,
                stock: 0,
                buyPrice: 0,
                sellPrice: line.unitPrice,
              );
          return _SelectedPart(item: item, qty: line.qty, unitPrice: line.unitPrice);
        }),
      );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref.watch(vehicleDetailProvider(widget.vehicleId));
    final inventory = ref.watch(partsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'ویرایش صورتحساب' : 'ثبت فاکتور')),
      body: vehicleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('خطا در بارگذاری')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('خودرو پیدا نشد.'));
          }
          _hydrateIfNeeded(detail, inventory);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _VehicleHeader(vehicle: detail.vehicle),
                const SizedBox(height: 22),
                const _SectionLabel('سرویس و تعمیر'),
                const SizedBox(height: 10),
                FormField<String>(
                  validator: (_) {
                    if (_title.text.trim().isEmpty) {
                      return 'عنوان کار را انتخاب یا تعریف کنید.';
                    }
                    return null;
                  },
                  builder: (field) {
                    final options = _titleOptions(inventory);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return DropdownMenu<String>(
                              controller: _title,
                              width: constraints.maxWidth,
                              enableFilter: true,
                              requestFocusOnTap: true,
                              label: const Text('عنوان کار'),
                              hintText: 'جستجو یا انتخاب از لیست',
                              dropdownMenuEntries: options
                                  .map((item) => DropdownMenuEntry<String>(value: item, label: item))
                                  .toList(),
                              onSelected: (value) {
                                setState(() {
                                  _title.text = value ?? '';
                                  _selectedQuickTitle = null;
                                });
                                field.didChange(_title.text);
                              },
                            );
                          },
                        ),
                        if (field.hasError) ...[
                          const SizedBox(height: 6),
                          Text(field.errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Stack(
                  children: [
                    TextFormField(
                      controller: _note,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'توضیحات',
                        hintText: 'وضعیت ماشین، یادداشت برای دفعه بعد...',
                        alignLabelWithHint: true,
                        contentPadding: EdgeInsets.fromLTRB(14, 14, 52, 14),
                      ),
                    ),
                    Positioned(
                      left: 4,
                      top: 4,
                        child: Material(
                          color: _listening
                              ? AppColors.danger.withValues(alpha: 0.18)
                              : AppColors.surface.withValues(alpha: 0.9),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _toggleVoiceNote,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                color: _listening ? AppColors.danger : AppColors.copper,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _SectionLabel('قطعات'),
                const SizedBox(height: 10),
                _PartSearchField(
                  allTitles: _titleOptions(inventory),
                  inventory: inventory,
                  onAdd: (name, partId, price) {
                    setState(() {
                      final existing = _selectedParts.where((p) => p.item.name == name).firstOrNull;
                      if (existing != null) {
                        existing.qty += 1;
                      } else {
                        final item = inventory.where((p) => p.id == partId).firstOrNull ??
                            PartItem(id: partId ?? 0, name: name, stock: 0, buyPrice: 0, sellPrice: price);
                        _selectedParts.add(_SelectedPart(item: item, unitPrice: price));
                      }
                    });
                  },
                  onDefineNew: _defineNewTitle,
                ),
                const SizedBox(height: 12),
                if (_selectedParts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'قطعه‌ای انتخاب نشده. می‌توانی فقط اجرت ثبت کنی.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  )
                else
                  ...List.generate(_selectedParts.length, (index) {
                    final part = _selectedParts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PartLineCard(
                        part: part,
                        onQty: (qty) => setState(() => part.qty = qty < 1 ? 1 : qty),
                        onPrice: (price) => setState(() => part.unitPrice = price),
                        onDelete: () => _removePart(index),
                      ),
                    );
                  }),
                const SizedBox(height: 22),
                const _SectionLabel('اجرت'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _labor,
                  keyboardType: TextInputType.number,
                  inputFormatters: [TomanInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'اجرت (تومان)',
                    hintText: '450,000',
                    suffixText: 'تومان',
                  ),
                ),
                const SizedBox(height: 8),
                _TotalsCard(labor: _laborAmount, parts: _partsAmount, total: _totalAmount),
                const SizedBox(height: 14),
                _PaidToggle(
                  paid: _paid,
                  onChanged: (value) => setState(() => _paid = value),
                ),
                const SizedBox(height: 14),
                _StylishSubmitButton(
                  label: _isEditing ? 'ذخیره تغییرات' : 'ثبت فاکتور',
                  loading: _saving,
                  icon: _isEditing ? Icons.save_rounded : Icons.receipt_long_rounded,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PartSearchField extends StatefulWidget {
  const _PartSearchField({
    required this.allTitles,
    required this.inventory,
    required this.onAdd,
    required this.onDefineNew,
  });

  final List<String> allTitles;
  final List<PartItem> inventory;
  final void Function(String name, int? partId, int price) onAdd;
  final VoidCallback onDefineNew;

  @override
  State<_PartSearchField> createState() => _PartSearchFieldState();
}

class _PartSearchFieldState extends State<_PartSearchField> {
  final _ctrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  PartItem? _selectedPart;

  @override
  void dispose() {
    _ctrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _onSelected(String? value) {
    if (value == null) return;
    _ctrl.text = value;
    final part = widget.inventory.where((p) => p.name == value).firstOrNull;
    setState(() {
      _selectedPart = part;
      _priceCtrl.text = part != null ? TomanInputFormatter.formatInt(part.sellPrice) : '';
    });
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    final price = TomanInputFormatter.parse(_priceCtrl.text);
    widget.onAdd(name, _selectedPart?.id, price);
    _ctrl.clear();
    _priceCtrl.clear();
    setState(() => _selectedPart = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => DropdownMenu<String>(
            controller: _ctrl,
            width: constraints.maxWidth,
            enableFilter: true,
            requestFocusOnTap: true,
            label: const Text('قطعه'),
            hintText: 'جستجو یا انتخاب...',
            dropdownMenuEntries: widget.allTitles
                .map((t) => DropdownMenuEntry<String>(value: t, label: t))
                .toList(),
            onSelected: _onSelected,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [TomanInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'قیمت واحد',
                  hintText: '0',
                  suffixText: 'تومان',
                ),
              ),
            ),
            const SizedBox(width: 10),
            _GlowActionButton(
              label: 'افزودن',
              icon: Icons.add_rounded,
              color: AppColors.copper,
              onTap: _submit,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SoftOutlineButton(
          label: 'تعریف قطعه جدید',
          icon: Icons.inventory_2_outlined,
          onTap: widget.onDefineNew,
        ),
      ],
    );
  }
}

class _PartLineCard extends StatelessWidget {
  const _PartLineCard({
    required this.part,
    required this.onQty,
    required this.onPrice,
    required this.onDelete,
  });

  final _SelectedPart part;
  final ValueChanged<int> onQty;
  final ValueChanged<int> onPrice;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(part.item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              IconButton(
                tooltip: 'حذف قطعه',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
              ),
            ],
          ),
          Row(
            children: [
              _QtyChip(
                icon: Icons.remove_rounded,
                onTap: () => onQty(part.qty - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('${part.qty}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              _QtyChip(
                icon: Icons.add_rounded,
                onTap: () => onQty(part.qty + 1),
                accent: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: part.price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [TomanInputFormatter()],
                  onChanged: (value) => onPrice(TomanInputFormatter.parse(value)),
                  decoration: const InputDecoration(
                    labelText: 'قیمت واحد',
                    suffixText: 'تومان',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'جمع این قطعه: ${MoneyFormat.toman(part.total)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QtyChip extends StatelessWidget {
  const _QtyChip({required this.icon, required this.onTap, this.accent = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.teal : AppColors.muted;
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _GlowActionButton extends StatelessWidget {
  const _GlowActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                Color.lerp(color, const Color(0xFF2A3038), 0.28)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftOutlineButton extends StatelessWidget {
  const _SoftOutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.teal.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StylishSubmitButton extends StatelessWidget {
  const _StylishSubmitButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PaidToggle extends StatelessWidget {
  const _PaidToggle({required this.paid, required this.onChanged});

  final bool paid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: paid ? AppColors.teal.withValues(alpha: 0.12) : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onChanged(!paid),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: paid ? AppColors.teal.withValues(alpha: 0.45) : AppColors.line.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: paid ? AppColors.teal : AppColors.muted.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  paid ? Icons.check_rounded : Icons.schedule_rounded,
                  color: paid ? Colors.white : AppColors.muted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paid ? 'تسویه شد' : 'الان تسویه شود؟',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: paid ? AppColors.teal : AppColors.cream,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      paid ? 'این فاکتور پرداخت‌شده ثبت می‌شود' : 'اگر نزنید، در بدهی مشتری می‌ماند',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.labor, required this.parts, required this.total});

  final int labor;
  final int parts;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _row('اجرت', labor, AppColors.teal),
          const SizedBox(height: 8),
          _row('قطعه', parts, AppColors.copper),
          const Divider(height: 20, color: AppColors.line),
          _row('جمع', total, AppColors.cream, bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, int amount, Color color, {bool bold = false}) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: color)),
        const Spacer(),
        Text(
          MoneyFormat.toman(amount),
          style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.plate.display,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vehicle.title}  ·  ${vehicle.ownerName}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
  }
}
