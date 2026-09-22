import '../../features/customers/domain/entities/customer.dart';
import '../../features/jobs/domain/entities/repair_job.dart';
import '../../features/parts/domain/entities/part_item.dart';
import '../../features/schedule/domain/entities/appointment.dart';
import '../../features/settings/domain/entities/shop_settings.dart';
import '../../features/vehicles/domain/entities/vehicle.dart';
import '../../features/visits/domain/entities/service_visit.dart';
import '../../features/visits/domain/repositories/visit_repository.dart';
import '../../features/vehicles/domain/repositories/vehicle_repository.dart';

class WorkshopStore {
  WorkshopStore();

  static WorkshopStore? _shared;
  static WorkshopStore get instance => _shared ??= WorkshopStore();

  final customers = <Customer>[];
  final vehicles = <Vehicle>[];
  final visits = <ServiceVisit>[];
  final jobs = <RepairJob>[];
  final parts = <PartItem>[];
  final appointments = <Appointment>[];
  ShopSettings settings = ShopSettings.defaults;

  int _nextCustomer = 1;
  int _nextVehicle = 1;
  int _nextVisit = 1;
  int _nextJob = 1;
  int _nextPart = 1;
  int _nextAppointment = 1;

  Vehicle saveVehicle(VehicleDraft draft) {
    upsertCustomer(CustomerDraft(name: draft.ownerName, phone: draft.ownerPhone));
    final vehicle = Vehicle(
      id: _nextVehicle++,
      plateKey: draft.plateKey,
      ownerName: draft.ownerName,
      ownerPhone: draft.ownerPhone,
      make: draft.make,
      model: draft.model,
      year: draft.year,
      color: draft.color,
      mileage: draft.mileage,
      platePhotoPath: draft.platePhotoPath,
      vin: draft.vin,
      nextServiceKm: draft.nextServiceKm,
    );
    vehicles.add(vehicle);
    return vehicle;
  }

  Customer upsertCustomer(CustomerDraft draft) {
    final existingIndex = customers.indexWhere((item) => item.phone == draft.phone);
    if (existingIndex >= 0) {
      final current = customers[existingIndex];
      final updated = Customer(
        id: current.id,
        name: draft.name.isEmpty ? current.name : draft.name,
        phone: draft.phone,
        note: draft.note.isEmpty ? current.note : draft.note,
      );
      customers[existingIndex] = updated;
      return updated;
    }
    final customer = Customer(
      id: _nextCustomer++,
      name: draft.name,
      phone: draft.phone,
      note: draft.note,
    );
    customers.add(customer);
    return customer;
  }

  ServiceVisit saveVisit(VisitDraft draft) {
    final lines = _resolvedPartLines(draft);
    final partsAmount = lines.fold<int>(0, (sum, line) => sum + line.total);
    final laborAmount = draft.laborAmount;
    final amount = draft.amount > 0 ? draft.amount : laborAmount + partsAmount;
    final visit = ServiceVisit(
      id: _nextVisit++,
      vehicleId: draft.vehicleId,
      happenedAt: draft.happenedAt,
      title: draft.title,
      note: draft.note,
      amount: amount,
      laborAmount: laborAmount,
      partsAmount: partsAmount > 0 ? partsAmount : draft.partsAmount,
      paid: draft.paid,
      partId: lines.where((line) => line.partId != null).firstOrNull?.partId,
      partLines: lines,
    );
    visits.add(visit);
    for (final line in lines) {
      if (line.partId != null) {
        consumePart(line.partId!, qty: line.qty);
      }
    }
    return visit;
  }

  ServiceVisit updateVisit(int id, VisitDraft draft) {
    final index = visits.indexWhere((item) => item.id == id);
    if (index < 0) {
      throw StateError('visit not found');
    }
    _restoreVisitStock(visits[index]);
    final lines = _resolvedPartLines(draft);
    final partsAmount = lines.fold<int>(0, (sum, line) => sum + line.total);
    final laborAmount = draft.laborAmount;
    final amount = draft.amount > 0 ? draft.amount : laborAmount + partsAmount;
    final visit = ServiceVisit(
      id: id,
      vehicleId: draft.vehicleId,
      happenedAt: draft.happenedAt,
      title: draft.title,
      note: draft.note,
      amount: amount,
      laborAmount: laborAmount,
      partsAmount: partsAmount > 0 ? partsAmount : draft.partsAmount,
      paid: draft.paid,
      partId: lines.where((line) => line.partId != null).firstOrNull?.partId,
      partLines: lines,
    );
    visits[index] = visit;
    for (final line in lines) {
      if (line.partId != null) {
        consumePart(line.partId!, qty: line.qty);
      }
    }
    return visit;
  }

  ServiceVisit setVisitPaid(int id, bool paid) {
    final index = visits.indexWhere((item) => item.id == id);
    final current = visits[index];
    final updated = ServiceVisit(
      id: current.id,
      vehicleId: current.vehicleId,
      happenedAt: current.happenedAt,
      title: current.title,
      note: current.note,
      amount: current.amount,
      laborAmount: current.laborAmount,
      partsAmount: current.partsAmount,
      paid: paid,
      partId: current.partId,
      partLines: current.partLines,
    );
    visits[index] = updated;
    return updated;
  }

  void deleteVisit(int id) {
    final index = visits.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }
    final visit = visits.removeAt(index);
    _restoreVisitStock(visit);
  }

  void _restoreVisitStock(ServiceVisit visit) {
    if (visit.partLines.isNotEmpty) {
      for (final line in visit.partLines) {
        if (line.partId != null) {
          consumePart(line.partId!, qty: -line.qty);
        }
      }
    } else if (visit.partId != null) {
      consumePart(visit.partId!, qty: -1);
    }
  }

  List<VisitPartLine> _resolvedPartLines(VisitDraft draft) {
    if (draft.partLines.isNotEmpty) {
      return draft.partLines;
    }
    if (draft.partId == null) {
      return const [];
    }
    final part = parts.where((item) => item.id == draft.partId).firstOrNull;
    return [
      VisitPartLine(
        partId: draft.partId,
        name: part?.name ?? 'قطعه',
        qty: 1,
        unitPrice: draft.partsAmount > 0 ? draft.partsAmount : (part?.sellPrice ?? 0),
      ),
    ];
  }

  void consumePart(int id, {int qty = 1}) {
    final index = parts.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }
    final current = parts[index];
    final stock = current.stock - qty;
    parts[index] = PartItem(
      id: current.id,
      name: current.name,
      sku: current.sku,
      stock: stock < 0 ? 0 : stock,
      buyPrice: current.buyPrice,
      sellPrice: current.sellPrice,
    );
  }

  RepairJob saveJob(JobDraft draft) {
    final vehicle = vehicles.where((item) => item.id == draft.vehicleId).firstOrNull;
    final job = RepairJob(
      id: _nextJob++,
      vehicleId: draft.vehicleId,
      title: draft.title,
      note: draft.note,
      status: draft.status,
      createdAt: DateTime.now(),
      vehicleTitle: vehicle?.title ?? '',
      plateKey: vehicle?.plateKey ?? '',
      ownerName: vehicle?.ownerName ?? '',
    );
    jobs.add(job);
    return job;
  }

  RepairJob updateJobStatus(int id, JobStatus status) {
    final index = jobs.indexWhere((item) => item.id == id);
    final current = jobs[index];
    final updated = RepairJob(
      id: current.id,
      vehicleId: current.vehicleId,
      title: current.title,
      note: current.note,
      status: status,
      createdAt: current.createdAt,
      vehicleTitle: current.vehicleTitle,
      plateKey: current.plateKey,
      ownerName: current.ownerName,
    );
    jobs[index] = updated;
    return updated;
  }

  PartItem savePart(PartDraft draft, {int? id}) {
    if (id != null) {
      final index = parts.indexWhere((item) => item.id == id);
      final updated = PartItem(
        id: id,
        name: draft.name,
        sku: draft.sku,
        stock: draft.stock,
        buyPrice: draft.buyPrice,
        sellPrice: draft.sellPrice,
      );
      parts[index] = updated;
      return updated;
    }
    final part = PartItem(
      id: _nextPart++,
      name: draft.name,
      sku: draft.sku,
      stock: draft.stock,
      buyPrice: draft.buyPrice,
      sellPrice: draft.sellPrice,
    );
    parts.add(part);
    return part;
  }

  Appointment saveAppointment(AppointmentDraft draft) {
    final item = Appointment(
      id: _nextAppointment++,
      vehicleId: draft.vehicleId,
      customerName: draft.customerName,
      plateText: draft.plateText,
      scheduledAt: draft.scheduledAt,
      bay: draft.bay,
      note: draft.note,
      status: draft.status,
    );
    appointments.add(item);
    return item;
  }

  Appointment updateAppointmentStatus(int id, AppointmentStatus status) {
    final index = appointments.indexWhere((item) => item.id == id);
    final current = appointments[index];
    final updated = Appointment(
      id: current.id,
      vehicleId: current.vehicleId,
      customerName: current.customerName,
      plateText: current.plateText,
      scheduledAt: current.scheduledAt,
      bay: current.bay,
      note: current.note,
      status: status,
    );
    appointments[index] = updated;
    return updated;
  }
}
