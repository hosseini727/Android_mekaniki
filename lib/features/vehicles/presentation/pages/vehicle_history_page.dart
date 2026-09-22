import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/pickup_sms_prompt.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../visits/domain/entities/service_visit.dart';
import 'package:kargah_yar/features/visits/presentation/providers/visit_providers.dart';
import 'package:kargah_yar/features/visits/presentation/widgets/visit_card.dart';
import 'package:kargah_yar/features/visits/presentation/widgets/visit_empty_state.dart';
import 'package:kargah_yar/features/visits/presentation/widgets/visit_summary_bar.dart';

class VehicleHistoryPage extends ConsumerWidget {
  const VehicleHistoryPage({super.key, required this.vehicleId});

  final int vehicleId;

  Future<void> _openAddVisit(BuildContext context, WidgetRef ref) async {
    final saved = await context.push<bool>(AppRoutes.addVisitPath(vehicleId));
    if (saved == true) {
      ref.invalidate(vehicleDetailProvider(vehicleId));
    }
  }

  Future<void> _openEditVisit(BuildContext context, WidgetRef ref, ServiceVisit visit) async {
    final saved = await context.push<bool>(AppRoutes.editVisitPath(vehicleId, visit.id));
    if (saved == true) {
      ref.invalidate(vehicleDetailProvider(vehicleId));
    }
  }

  Future<void> _deleteVisit(BuildContext context, WidgetRef ref, ServiceVisit visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف مراجعه'),
        content: Text('«${visit.title}» از تاریخچه این ماشین حذف شود؟'),
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
    await ref.read(visitRepositoryProvider).delete(visit.id);
    ref.invalidate(vehicleDetailProvider(vehicleId));
    ref.invalidate(billsProvider);
    ref.invalidate(reportsProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(dashboardSnapshotProvider);
    ref.invalidate(partsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مراجعه حذف شد.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(vehicleDetailProvider(vehicleId));

    return detailAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('خطا در بارگذاری پرونده.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(vehicleDetailProvider(vehicleId)),
                child: const Text('تلاش دوباره'),
              ),
            ],
          ),
        ),
      ),
      data: (detail) {
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('خودرو پیدا نشد.')),
          );
        }
        final vehicle = detail.vehicle;
        final visits = detail.visits;
        final money = NumberFormat.decimalPattern('fa');

        return Scaffold(
          appBar: AppBar(
            title: Text(vehicle.title),
            actions: [
              IconButton(
                tooltip: 'ثبت فاکتور',
                onPressed: () => _openAddVisit(context, ref),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddVisit(context, ref),
            backgroundColor: AppColors.copper,
            foregroundColor: AppColors.onPrimary,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'ثبت فاکتور',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.copper,
            onRefresh: () async {
              ref.invalidate(vehicleDetailProvider(vehicleId));
              await ref.read(vehicleDetailProvider(vehicleId).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                _VehicleProfileCard(vehicle: vehicle, money: money),
                const SizedBox(height: 18),
                VisitSummaryBar(
                  visitCount: visits.length,
                  totalAmount: detail.totalAmount,
                ),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Text(
                      'تاریخچه مراجعات',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (visits.isEmpty)
                  const VisitEmptyState()
                else
                  ...List.generate(
                    visits.length,
                    (index) =>                     VisitCard(
                      visit: visits[index],
                      isFirst: index == 0,
                      isLast: index == visits.length - 1,
                      onEdit: () => _openEditVisit(context, ref, visits[index]),
                      onDelete: () => _deleteVisit(context, ref, visits[index]),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    final shop = ref.read(settingsProvider).valueOrNull;
                    PickupSmsPrompt.show(
                      context: context,
                      vehicle: vehicle,
                      jobTitle: 'تعمیر',
                      shop: shop,
                    );
                  },
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('پیامک تحویل ماشین'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cream,
                    side: const BorderSide(color: AppColors.line),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VehicleProfileCard extends StatelessWidget {
  const _VehicleProfileCard({
    required this.vehicle,
    required this.money,
  });

  final Vehicle vehicle;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F1EA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1D2430), width: 1.4),
              ),
              child: Text(
                vehicle.plate.display,
                style: const TextStyle(
                  color: Color(0xFF1D2430),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (vehicle.isDueForService)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'سرویس دوره‌ای این ماشین سررسید شده.',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
              ),
            ),
          _InfoRow(icon: Icons.person_outline_rounded, label: 'مالک', value: vehicle.ownerName),
          _InfoRow(icon: Icons.phone_outlined, label: 'موبایل', value: vehicle.ownerPhone),
          _InfoRow(
            icon: Icons.palette_outlined,
            label: 'رنگ / سال',
            value: '${vehicle.color}  ·  ${vehicle.year}',
          ),
          _InfoRow(
            icon: Icons.speed_outlined,
            label: 'کیلومتر',
            value: '${money.format(vehicle.mileage)} km',
          ),
          if (vehicle.vin.isNotEmpty)
            _InfoRow(icon: Icons.pin_outlined, label: 'شاسی', value: vehicle.vin),
          if (vehicle.nextServiceKm > 0)
            _InfoRow(
              icon: Icons.event_repeat_rounded,
              label: 'سرویس بعدی',
              value: vehicle.isDueForService
                  ? '${money.format(vehicle.nextServiceKm)} km  ·  سررسید'
                  : '${money.format(vehicle.nextServiceKm)} km',
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
