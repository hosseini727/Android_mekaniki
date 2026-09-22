import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/service_visit.dart';
import '../../../../app/di/providers.dart';

class VehicleDetail {
  const VehicleDetail({
    required this.vehicle,
    required this.visits,
    required this.totalAmount,
  });

  final Vehicle vehicle;
  final List<ServiceVisit> visits;
  final int totalAmount;
}

final vehicleDetailProvider = FutureProvider.family<VehicleDetail?, int>((ref, vehicleId) async {
  final vehicle = await ref.read(vehicleRepositoryProvider).findById(vehicleId);
  if (vehicle == null) {
    return null;
  }
  final visitRepo = ref.read(visitRepositoryProvider);
  final visits = await visitRepo.ofVehicle(vehicleId);
  final totalAmount = await visitRepo.totalAmountOf(vehicleId);
  return VehicleDetail(vehicle: vehicle, visits: visits, totalAmount: totalAmount);
});
