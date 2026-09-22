import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.auto_awesome,
    this.embedded = false,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              title: Text(title),
            ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(icon, color: AppColors.copper, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.8,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            const Text(
              'این ماژول در مرحله بعد پیاده می‌شود. اسکلت محصول آماده است.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
