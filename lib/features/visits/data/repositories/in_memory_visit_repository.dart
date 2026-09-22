import '../../../../app/data/workshop_store.dart';
import '../../domain/entities/service_visit.dart';
import '../../domain/repositories/visit_repository.dart';

class InMemoryVisitRepository implements VisitRepository {
  InMemoryVisitRepository({WorkshopStore? store}) : _store = store ?? WorkshopStore.instance;

  final WorkshopStore _store;

  @override
  Future<List<ServiceVisit>> all() async {
    return _store.visits.toList()..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
  }

  @override
  Future<List<ServiceVisit>> ofVehicle(int vehicleId) async {
    return _store.visits.where((visit) => visit.vehicleId == vehicleId).toList()
      ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
  }

  @override
  Future<ServiceVisit> save(VisitDraft draft) async {
    return _store.saveVisit(draft);
  }

  @override
  Future<ServiceVisit?> findById(int id) async {
    return _store.visits.where((visit) => visit.id == id).firstOrNull;
  }

  @override
  Future<ServiceVisit> update(int id, VisitDraft draft) async {
    return _store.updateVisit(id, draft);
  }

  @override
  Future<void> setPaid(int id, bool paid) async {
    _store.setVisitPaid(id, paid);
  }

  @override
  Future<void> delete(int id) async {
    _store.deleteVisit(id);
  }

  @override
  Future<int> totalAmountOf(int vehicleId) async {
    return _store.visits
        .where((visit) => visit.vehicleId == vehicleId)
        .fold<int>(0, (sum, visit) => sum + visit.amount);
  }

  @override
  Future<int> unpaidAmountOfPhone(String phone) async {
    final ids = _store.vehicles.where((car) => car.ownerPhone == phone).map((car) => car.id).toSet();
    return _store.visits
        .where((visit) => ids.contains(visit.vehicleId) && !visit.paid)
        .fold<int>(0, (sum, visit) => sum + visit.amount);
  }
}
