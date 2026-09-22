import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/local_auth_repository.dart';
import '../../features/auth/domain/entities/mechanic_account.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/bills/presentation/pages/bills_page.dart';
import '../../features/customers/data/repositories/in_memory_customer_repository.dart';
import '../../features/customers/data/repositories/sqlite_customer_repository.dart';
import '../../features/customers/domain/repositories/customer_repository.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/jobs/data/repositories/in_memory_job_repository.dart';
import '../../features/jobs/data/repositories/sqlite_job_repository.dart';
import '../../features/jobs/domain/entities/repair_job.dart';
import '../../features/jobs/domain/repositories/job_repository.dart';
import '../../features/parts/data/repositories/in_memory_part_repository.dart';
import '../../features/parts/data/repositories/sqlite_part_repository.dart';
import '../../features/parts/domain/entities/part_item.dart';
import '../../features/parts/domain/repositories/part_repository.dart';
import '../../features/reports/domain/entities/workshop_report.dart';
import '../../features/reports/domain/entities/period_report.dart';
import '../../features/reports/domain/report_analytics.dart';
import '../../features/shell/domain/dashboard_snapshot.dart';
import '../../features/schedule/data/repositories/in_memory_schedule_repository.dart';
import '../../features/schedule/data/repositories/sqlite_schedule_repository.dart';
import '../../features/schedule/domain/entities/appointment.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../../features/settings/data/repositories/in_memory_settings_repository.dart';
import '../../features/settings/data/repositories/sqlite_settings_repository.dart';
import '../../features/settings/domain/entities/shop_settings.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/vehicles/data/repositories/in_memory_vehicle_repository.dart';
import '../../features/vehicles/data/repositories/sqlite_vehicle_repository.dart';
import '../../features/vehicles/data/services/plate_ocr_service.dart';
import '../../features/vehicles/domain/repositories/vehicle_repository.dart';
import '../../features/visits/data/repositories/in_memory_visit_repository.dart';
import '../../features/visits/data/repositories/sqlite_visit_repository.dart';
import '../../features/visits/domain/repositories/visit_repository.dart';

bool get _useMemory => kIsWeb;

final activationStateProvider = StateProvider<bool>((ref) => false);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository();
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return _useMemory ? InMemoryVehicleRepository() : SqliteVehicleRepository();
});

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return _useMemory ? InMemoryVisitRepository() : SqliteVisitRepository();
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return _useMemory ? InMemoryJobRepository() : SqliteJobRepository();
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return _useMemory ? InMemoryCustomerRepository() : SqliteCustomerRepository();
});

final partRepositoryProvider = Provider<PartRepository>((ref) {
  return _useMemory ? InMemoryPartRepository() : SqlitePartRepository();
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return _useMemory ? InMemoryScheduleRepository() : SqliteScheduleRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return _useMemory ? InMemorySettingsRepository() : SqliteSettingsRepository();
});

final plateOcrProvider = Provider<PlateOcrService>((ref) {
  return PlateOcrService();
});

final authStateProvider = NotifierProvider<AuthController, MechanicAccount?>(
  AuthController.new,
);

final vehiclesProvider = FutureProvider((ref) {
  return ref.watch(vehicleRepositoryProvider).all();
});

final jobsProvider = FutureProvider<List<RepairJob>>((ref) {
  return ref.watch(jobRepositoryProvider).all();
});

final partsProvider = FutureProvider<List<PartItem>>((ref) {
  return ref.watch(partRepositoryProvider).all();
});

final scheduleProvider = FutureProvider<List<Appointment>>((ref) {
  return ref.watch(scheduleRepositoryProvider).all();
});

final settingsProvider = FutureProvider<ShopSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).read();
});

final customersProvider = FutureProvider<CustomerBundle>((ref) async {
  final customers = await ref.watch(customerRepositoryProvider).all();
  final vehicles = await ref.watch(vehicleRepositoryProvider).all();
  final visits = await ref.watch(visitRepositoryProvider).all();
  final debt = <String, int>{};
  for (final visit in visits.where((item) => !item.paid)) {
    final car = vehicles.where((item) => item.id == visit.vehicleId).firstOrNull;
    if (car == null) {
      continue;
    }
    debt[car.ownerPhone] = (debt[car.ownerPhone] ?? 0) + visit.amount;
  }
  return CustomerBundle(customers: customers, vehicles: vehicles, debtByPhone: debt);
});

final billsProvider = FutureProvider<List<BillItem>>((ref) async {
  final visits = await ref.watch(visitRepositoryProvider).all();
  final vehicles = await ref.watch(vehicleRepositoryProvider).all();
  return visits
      .map(
        (visit) => BillItem(
          visit: visit,
          vehicle: vehicles.where((car) => car.id == visit.vehicleId).firstOrNull,
        ),
      )
      .toList();
});

final reportsProvider = FutureProvider<WorkshopReport>((ref) async {
  final visits = await ref.watch(visitRepositoryProvider).all();
  final vehicles = await ref.watch(vehicleRepositoryProvider).all();
  final appointments = await ref.watch(scheduleRepositoryProvider).all();
  final parts = await ref.watch(partRepositoryProvider).all();
  final labor = visits.fold<int>(0, (sum, item) => sum + item.laborAmount);
  final partsTotal = visits.fold<int>(0, (sum, item) => sum + item.partsAmount);
  final sales = visits.fold<int>(0, (sum, item) => sum + item.amount);
  final unpaid = visits.where((item) => !item.paid).fold<int>(0, (sum, item) => sum + item.amount);
  return WorkshopReport(
    totalSales: sales,
    laborTotal: labor,
    partsTotal: partsTotal,
    visitCount: visits.length,
    vehicleCount: vehicles.length,
    openJobs: visits.where((item) => !item.paid).length,
    openAppointments: appointments.where((item) => item.status != AppointmentStatus.done).length,
    lowParts: parts.where((item) => item.isLow).length,
    unpaidTotal: unpaid,
    dueServiceCount: vehicles.where((car) => car.isDueForService).length,
  );
});

final periodReportProvider = FutureProvider.family<PeriodReport, ReportPeriod>((ref, period) async {
  final visits = await ref.watch(visitRepositoryProvider).all();
  final vehicles = await ref.watch(vehicleRepositoryProvider).all();
  final parts = await ref.watch(partRepositoryProvider).all();
  return ReportAnalytics.build(
    period: period,
    visits: visits,
    vehicles: vehicles,
    parts: parts,
  );
});

final dashboardSnapshotProvider = FutureProvider<DashboardSnapshot>((ref) async {
  final report = await ref.watch(reportsProvider.future);
  final appointments = await ref.watch(scheduleRepositoryProvider).all();
  final now = DateTime.now();
  final today = appointments.where((item) {
    return item.scheduledAt.year == now.year &&
        item.scheduledAt.month == now.month &&
        item.scheduledAt.day == now.day;
  }).length;
  return DashboardSnapshot(
    unpaidTotal: report.unpaidTotal,
    openJobs: report.openJobs,
    lowParts: report.lowParts,
    dueServiceCount: report.dueServiceCount,
    todayAppointments: today,
  );
});

class AuthController extends Notifier<MechanicAccount?> {
  @override
  MechanicAccount? build() => ref.read(authRepositoryProvider).currentAccount;

  Future<void> restoreIfNeeded() async {
    if (state != null) {
      return;
    }
    final account = ref.read(authRepositoryProvider).currentAccount;
    if (account != null) {
      state = await _withSettings(account);
    }
  }

  Future<void> login({required String phone, required String password}) async {
    final account = await ref.read(authRepositoryProvider).login(
          phone: phone,
          password: password,
        );
    state = await _withSettings(account);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }

  void applySettings(ShopSettings settings) {
    final current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(
      shopName: settings.shopName,
      ownerName: settings.ownerName,
      phone: settings.phone.isNotEmpty ? settings.phone : current.phone,
    );
  }

  Future<MechanicAccount> _withSettings(MechanicAccount account) async {
    final settings = await ref.read(settingsRepositoryProvider).read();
    return account.copyWith(
      shopName: settings.shopName,
      ownerName: settings.ownerName,
      phone: settings.phone.isNotEmpty ? settings.phone : account.phone,
    );
  }
}
