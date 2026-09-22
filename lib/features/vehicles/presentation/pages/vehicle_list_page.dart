import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kargah_yar/app/di/providers.dart';
import 'package:kargah_yar/app/router/app_routes.dart';
import 'package:kargah_yar/core/theme/app_colors.dart';
import 'package:kargah_yar/core/widgets/app_empty_state.dart';
import 'package:kargah_yar/core/widgets/status_chip.dart';

class VehicleListPage extends ConsumerStatefulWidget {
  const VehicleListPage({super.key});

  @override
  ConsumerState<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends ConsumerState<VehicleListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncCars = ref.watch(vehiclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('تاریخچه خودروها')),
      body: asyncCars.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('خطا در بارگذاری خودروها')),
        data: (cars) {
          final needle = _query.trim();
          final visible = needle.isEmpty
              ? cars
              : cars.where((car) {
                  return car.plate.display.contains(needle) ||
                      car.ownerName.contains(needle) ||
                      car.ownerPhone.contains(needle) ||
                      car.vin.contains(needle);
                }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'جستجوی پلاک، مالک، شاسی...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.directions_car_filled_rounded,
                        title: 'خودرویی پیدا نشد',
                        body: 'از پذیرش پلاک شروع کن یا جستجو را عوض کن.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final car = visible[index];
                          return ListTile(
                            onTap: () => context.push(AppRoutes.vehicleHistoryPath(car.id)),
                            tileColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.line),
                            ),
                            title: Text(car.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              '${car.plate.display}  ·  ${car.ownerName}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            trailing: car.isDueForService
                                ? const StatusChip(label: 'سرویس', color: AppColors.danger)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
