import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_format.dart';

class VisitSummaryBar extends StatelessWidget {
  const VisitSummaryBar({
    super.key,
    required this.visitCount,
    required this.totalAmount,
  });

  final int visitCount;
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.copper.withValues(alpha: 0.18),
            AppColors.surfaceHigh,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              icon: Icons.history_rounded,
              label: 'مراجعات',
              value: '$visitCount بار',
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.line),
          Expanded(
            child: _Stat(
              icon: Icons.payments_outlined,
              label: 'جمع کل',
              value: MoneyFormat.toman(totalAmount),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.copper, size: 20),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
