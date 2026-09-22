import '../entities/service_visit.dart';

abstract class VisitRepository {
  Future<List<ServiceVisit>> all();
  Future<List<ServiceVisit>> ofVehicle(int vehicleId);
  Future<ServiceVisit?> findById(int id);
  Future<ServiceVisit> save(VisitDraft draft);
  Future<ServiceVisit> update(int id, VisitDraft draft);
  Future<void> setPaid(int id, bool paid);
  Future<void> delete(int id);
  Future<int> totalAmountOf(int vehicleId);
  Future<int> unpaidAmountOfPhone(String phone);
}

class VisitDraft {
  const VisitDraft({
    required this.vehicleId,
    required this.happenedAt,
    required this.title,
    required this.note,
    required this.amount,
    this.laborAmount = 0,
    this.partsAmount = 0,
    this.paid = false,
    this.partId,
    this.partLines = const [],
  });

  final int vehicleId;
  final DateTime happenedAt;
  final String title;
  final String note;
  final int amount;
  final int laborAmount;
  final int partsAmount;
  final bool paid;
  final int? partId;
  final List<VisitPartLine> partLines;
}
