import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bill_pdf.dart';
import '../../../../core/utils/bill_share.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/pickup_sms.dart';
import '../../../../core/utils/shamsi_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../visits/domain/entities/service_visit.dart';
import '../../../visits/presentation/providers/visit_providers.dart';

class BillsPage extends ConsumerStatefulWidget {
  const BillsPage({super.key});

  @override
  ConsumerState<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends ConsumerState<BillsPage> {
  bool _unpaidOnly = false;
  String _query = '';

  bool _matchesQuery(BillItem item, String needle) {
    if (needle.isEmpty) return true;
    final vehicle = item.vehicle;
    if (vehicle == null) return false;
    final q = _digitsOnly(needle);
    final phone = _digitsOnly(vehicle.ownerPhone);
    final plateKey = _digitsOnly(vehicle.plateKey);
    final plateDisplay = vehicle.plate.display.replaceAll(' ', '');
    return phone.contains(q) ||
        plateKey.contains(q) ||
        plateDisplay.contains(needle) ||
        vehicle.plate.display.contains(needle) ||
        vehicle.ownerPhone.contains(needle);
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

  @override
  Widget build(BuildContext context) {
    final asyncBills = ref.watch(billsProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    return asyncBills.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('خطا در بارگذاری صورتحساب‌ها')),
      data: (bills) {
        final needle = _query.trim();
        final filtered = bills.where((item) => _matchesQuery(item, needle)).toList();
        final visible = _unpaidOnly ? filtered.where((item) => !item.visit.paid).toList() : filtered;
        final unpaid = filtered.where((item) => !item.visit.paid).fold<int>(0, (sum, item) => sum + item.visit.amount);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const Text('صورتحساب کارگاه', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'فاکتور رسمی نیست. بدهی، تسویه، PDF، ویرایش، حذف و ارسال متن برای مشتری اینجاست.',
              style: TextStyle(color: AppColors.muted, height: 1.6),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'جستجو با پلاک یا موبایل...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Text('بدهی باز: ${MoneyFormat.toman(unpaid)}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('فقط پرداخت‌نشده‌ها', style: TextStyle(fontSize: 14)),
              value: _unpaidOnly,
              activeColor: AppColors.primary,
              onChanged: (value) => setState(() => _unpaidOnly = value),
            ),
            const SizedBox(height: 8),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: AppEmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: needle.isEmpty ? 'موردی نیست' : 'نتیجه‌ای پیدا نشد',
                  body: needle.isEmpty
                      ? 'با ثبت فاکتور، صورتحساب اینجا می‌آید.'
                      : 'پلاک یا موبایل دیگری را امتحان کن.',
                ),
              )
            else
              ...visible.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BillTile(
                      item: item,
                      onTogglePaid: () async {
                        await ref.read(visitRepositoryProvider).setPaid(item.visit.id, !item.visit.paid);
                        _refreshBills(ref, item.vehicle?.id);
                      },
                      onExportPdf: () async {
                        try {
                          await BillPdf.preview(
                            visit: item.visit,
                            vehicle: item.vehicle,
                            shop: settings,
                          );
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ساخت PDF ممکن نشد. دوباره امتحان کن.')),
                            );
                          }
                        }
                      },
                      onShare: () async {
                        final phone = item.vehicle?.ownerPhone ?? '';
                        if (phone.trim().isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('موبایل مشتری ثبت نشده. اول شماره را در پرونده بگذار.'),
                              ),
                            );
                          }
                          return;
                        }
                        final text = BillShare.text(
                          visit: item.visit,
                          vehicle: item.vehicle,
                          shop: settings,
                        );
                        final result = await PickupSms.openOnDevice(phone: phone, body: text);
                        if (!context.mounted) {
                          return;
                        }
                        switch (result) {
                          case SmsSendResult.opened:
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('پیامک باز شد. ارسال را روی گوشی تأیید کن.')),
                            );
                          case SmsSendResult.copied:
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('متن کپی شد. در پیامک برای مشتری بفرست.')),
                            );
                          case SmsSendResult.missingPhone:
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('موبایل مشتری ثبت نشده.')),
                            );
                        }
                      },
                      onEdit: item.vehicle == null
                          ? null
                          : () async {
                              final saved = await context.push<bool>(
                                AppRoutes.editVisitPath(item.vehicle!.id, item.visit.id),
                              );
                              if (saved == true) {
                                _refreshBills(ref, item.vehicle?.id);
                              }
                            },
                      onDelete: () => _deleteBill(context, ref, item),
                    ),
                  )),
          ],
        );
      },
    );
  }

  void _refreshBills(WidgetRef ref, int? vehicleId) {
    ref.invalidate(billsProvider);
    ref.invalidate(reportsProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(dashboardSnapshotProvider);
    ref.invalidate(partsProvider);
    if (vehicleId != null) {
      ref.invalidate(vehicleDetailProvider(vehicleId));
    }
  }

  Future<void> _deleteBill(BuildContext context, WidgetRef ref, BillItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف صورتحساب'),
        content: Text('«${item.visit.title}» حذف شود؟ موجودی قطعات هم برمی‌گردد.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(visitRepositoryProvider).delete(item.visit.id);
    _refreshBills(ref, item.vehicle?.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صورتحساب حذف شد.')),
      );
    }
  }
}

class BillItem {
  const BillItem({required this.visit, required this.vehicle});

  final ServiceVisit visit;
  final Vehicle? vehicle;
}

class _BillTile extends StatelessWidget {
  const _BillTile({
    required this.item,
    required this.onTogglePaid,
    required this.onShare,
    required this.onExportPdf,
    this.onEdit,
    this.onDelete,
  });

  final BillItem item;
  final VoidCallback onTogglePaid;
  final VoidCallback onShare;
  final VoidCallback onExportPdf;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final visit = item.visit;
    final vehicle = item.vehicle;
    final description = visit.note.trim().isNotEmpty ? visit.note.trim() : visit.title;
    return AppCard(
      onTap: vehicle == null ? null : () => context.push(AppRoutes.vehicleHistoryPath(vehicle.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ShamsiFormat.full(visit.happenedAt),
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle == null ? 'خودرو نامشخص' : vehicle.listLabel,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                visit.paid ? 'تسویه' : 'بدهی',
                style: TextStyle(
                  color: visit.paid ? AppColors.teal : AppColors.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.start,
            textDirection: TextDirection.rtl,
            style: const TextStyle(height: 1.55, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            MoneyFormat.toman(visit.amount),
            style: const TextStyle(
              color: AppColors.copper,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          if (visit.laborAmount > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _BreakdownChip(
                label: 'اجرت',
                amount: visit.laborAmount,
                color: AppColors.teal,
              ),
            ),
          ],
          if (visit.partsAmount > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _BreakdownChip(
                label: 'قطعه',
                amount: visit.partsAmount,
                color: AppColors.copper,
              ),
            ),
          ],
          if (visit.partLines.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...visit.partLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${line.name}${line.qty > 1 ? ' × ${line.qty}' : ''}  ·  ${MoneyFormat.compact(line.total)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton(
                label: visit.paid ? 'برگشت به بدهی' : 'تسویه شد',
                icon: visit.paid ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                color: visit.paid ? AppColors.muted : AppColors.teal,
                onTap: onTogglePaid,
              ),
              _actionButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_rounded,
                color: AppColors.primaryDark,
                onTap: onExportPdf,
              ),
              _actionButton(
                label: 'پیامک',
                icon: Icons.sms_outlined,
                color: AppColors.copper,
                onTap: onShare,
              ),
              if (onEdit != null)
                _actionButton(
                  label: 'ویرایش',
                  icon: Icons.edit_outlined,
                  color: AppColors.muted,
                  onTap: onEdit!,
                ),
              if (onDelete != null)
                _actionButton(
                  label: 'حذف',
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  onTap: onDelete!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  const _BreakdownChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label  ${MoneyFormat.compact(amount)}',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
