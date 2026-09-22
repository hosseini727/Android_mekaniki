import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class VisitEmptyState extends StatelessWidget {
  const VisitEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.copperSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.build_circle_outlined, color: AppColors.copper, size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'هنوز کاری ثبت نشده',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'اولین مراجعه این ماشین را ثبت کن.\nبعداً در فاکتور و گزارش‌ها می‌آید.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.6, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
