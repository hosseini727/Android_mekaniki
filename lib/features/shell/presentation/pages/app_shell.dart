import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kargah_yar/app/di/providers.dart';
import 'package:kargah_yar/app/router/app_routes.dart';
import 'package:kargah_yar/core/constants/app_info.dart';
import 'package:kargah_yar/core/theme/app_colors.dart';
import 'package:kargah_yar/core/widgets/app_bottom_nav.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  bool _isMainTab(String location) {
    return location == AppRoutes.home ||
        location == AppRoutes.intake ||
        location == AppRoutes.invoices ||
        location == AppRoutes.voice ||
        location.startsWith('${AppRoutes.voice}?');
  }

  int _indexFor(String location) {
    if (location == AppRoutes.home) {
      return 0;
    }
    if (location == AppRoutes.intake) {
      return 1;
    }
    if (location == AppRoutes.invoices) {
      return 2;
    }
    if (location == AppRoutes.voice || location.startsWith('${AppRoutes.voice}?')) {
      return 3;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final index = _indexFor(location);
    final showShellAppBar = _isMainTab(location);

    return Scaffold(
      appBar: showShellAppBar
          ? AppBar(
              centerTitle: index != 3,
              title: index == 3
                  ? const Text('ثبت صوتی فاکتور')
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/images/logo.png', width: 32, height: 32),
                        ),
                        const SizedBox(width: 8),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(AppInfo.website),
                        ),
                      ],
                    ),
              actions: [
                IconButton(
                  tooltip: 'خروج',
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            )
          : null,
      body: child,
      bottomNavigationBar: AppBottomNav(
        selectedIndex: index,
        onSelected: (value) {
          switch (value) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.intake);
            case 2:
              context.go(AppRoutes.invoices);
            case 3:
              context.go(AppRoutes.voice);
          }
        },
        items: const [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'خانه',
          ),
          AppBottomNavItem(
            icon: Icons.add_circle_outline_rounded,
            selectedIcon: Icons.add_circle_rounded,
            label: 'پذیرش',
          ),
          AppBottomNavItem(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
            label: 'صورتحساب',
          ),
          AppBottomNavItem(
            icon: Icons.mic_none_rounded,
            selectedIcon: Icons.mic_rounded,
            label: 'صوتی',
          ),
        ],
      ),
      backgroundColor: AppColors.voidBg,
    );
  }
}
