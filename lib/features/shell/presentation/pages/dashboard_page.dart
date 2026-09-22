import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kargah_yar/app/di/providers.dart';
import 'package:kargah_yar/app/router/app_routes.dart';
import 'package:kargah_yar/core/constants/app_info.dart';
import 'package:kargah_yar/core/constants/app_modules.dart';
import 'package:kargah_yar/core/constants/app_spacing.dart';
import 'package:kargah_yar/core/theme/app_colors.dart';
import 'package:kargah_yar/core/utils/money_format.dart';
import 'package:kargah_yar/core/widgets/app_card.dart';
import 'package:kargah_yar/features/shell/domain/dashboard_snapshot.dart';

List<Color> _cardFaceGradient(Color accent) {
  return [
    Color.lerp(accent, Colors.white, 0.22)!,
    Color.lerp(accent, Colors.white, 0.38)!,
    Color.lerp(accent, Colors.white, 0.52)!,
  ];
}

BoxDecoration _menuCard3D(Color accent, {double radius = 20}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: _cardFaceGradient(accent),
      stops: const [0.0, 0.5, 1.0],
    ),
    border: Border.all(color: accent.withValues(alpha: 0.28), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.30),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

Widget _iconBadge3D(Color accent, IconData icon, {double size = 26, double box = 52}) {
  return Container(
    width: box,
    height: box,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(accent, Colors.white, 0.35)!,
          accent,
          Color.lerp(accent, Colors.black, 0.12)!,
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.42),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.9),
          blurRadius: 0,
          offset: const Offset(-1, -2),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: size),
  );
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _query = '';

  static const _featured = [AppModule.intake, AppModule.voice];
  static const _grid = [
    AppModule.vehicles,
    AppModule.customers,
    AppModule.reports,
    AppModule.parts,
  ];
  static const _settings = AppModule.settings;

  AppModuleDef _def(AppModule module) =>
      appModules.firstWhere((item) => item.module == module);

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authStateProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final shopName = (settings?.shopName.isNotEmpty ?? false)
        ? settings!.shopName
        : (account?.shopName ?? AppInfo.website);
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? [];
    final needle = _query.trim();
    final hits = needle.isEmpty
        ? <dynamic>[]
        : vehicles.where((car) {
            return car.plate.display.contains(needle) ||
                car.plateKey.contains(needle) ||
                car.ownerName.contains(needle) ||
                car.ownerPhone.contains(needle) ||
                car.vin.contains(needle) ||
                car.title.contains(needle);
          }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'پلاک، نام یا موبایل را جستجو کن.',
                  style: TextStyle(color: AppColors.muted, height: 1.7, fontSize: 15),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'جستجوی پلاک، مشتری، موبایل، شاسی...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                if (hits.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...hits.take(5).map(
                    (car) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        onTap: () => context.push(AppRoutes.vehicleHistoryPath(car.id)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${car.plate.display}  ·  ${car.ownerName}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                snapshot.when(
                  loading: () => const SizedBox(height: 72),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (data) => _LiveStats(snapshot: data),
                ),
                const SizedBox(height: AppSpacing.xl),
                ..._featured.map(
                  (module) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FeatureCard(
                      item: _def(module),
                      onTap: () => context.push(_def(module).route),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _SquareCard(
                        item: _def(_grid[0]),
                        onTap: () => context.push(_def(_grid[0]).route),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SquareCard(
                        item: _def(_grid[1]),
                        onTap: () => context.push(_def(_grid[1]).route),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SquareCard(
                        item: _def(_grid[2]),
                        onTap: () => context.push(_def(_grid[2]).route),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SquareCard(
                        item: _def(_grid[3]),
                        onTap: () => context.push(_def(_grid[3]).route),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  item: _def(_settings),
                  onTap: () => context.push(_def(_settings).route),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveStats extends StatelessWidget {
  const _LiveStats({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'بدهی‌ها',
            value: MoneyFormat.toman(snapshot.unpaidTotal),
            color: AppColors.danger,
            onTap: () => context.push(AppRoutes.invoices),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'کار باز',
            value: '${snapshot.openJobs}',
            color: AppColors.copper,
            onTap: () => context.push(AppRoutes.invoices),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

/// کارت بزرگ افقی — شبیه منوی نمونه
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.item, required this.onTap});

  final AppModuleDef item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 118,
          decoration: _menuCard3D(item.color),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -20,
                top: -30,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: -16,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: Color.lerp(AppColors.cream, item.color, 0.15),
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.cream.withValues(alpha: 0.72),
                              fontSize: 12.5,
                              height: 1.55,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _iconBadge3D(item.color, item.icon),
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

/// کارت مربعی متوسط
class _SquareCard extends StatelessWidget {
  const _SquareCard({required this.item, required this.onTap});

  final AppModuleDef item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 132,
          decoration: _menuCard3D(item.color, radius: 18),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconBadge3D(item.color, item.icon, size: 20, box: 42),
              const Spacer(),
              Text(
                item.title,
                style: TextStyle(
                  color: Color.lerp(AppColors.cream, item.color, 0.12),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
