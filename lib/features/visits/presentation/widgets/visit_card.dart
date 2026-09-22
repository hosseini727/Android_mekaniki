import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/shamsi_format.dart';
import '../../domain/entities/service_visit.dart';

class VisitCard extends StatelessWidget {
  const VisitCard({
    super.key,
    required this.visit,
    required this.isFirst,
    required this.isLast,
    this.onDelete,
    this.onEdit,
  });

  final ServiceVisit visit;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final date = ShamsiFormat.full(visit.happenedAt);
    final description = visit.note.trim().isNotEmpty ? visit.note.trim() : visit.title;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(width: 2, color: AppColors.line.withValues(alpha: 0.6)),
                  ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isFirst ? AppColors.copper : AppColors.surfaceHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFirst ? AppColors.copper : AppColors.line,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.line.withValues(alpha: 0.6)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            date,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (onEdit != null)
                          IconButton(
                            tooltip: 'ویرایش',
                            onPressed: onEdit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.cream),
                          ),
                        if (onDelete != null)
                          IconButton(
                            tooltip: 'حذف مراجعه',
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.start,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        height: 1.55,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          MoneyFormat.toman(visit.amount),
                          style: const TextStyle(
                            color: AppColors.copper,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        const Spacer(),
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
                  ],
                ),
              ),
            ),
          ),
        ],
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
