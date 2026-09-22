import '../../../../app/data/workshop_store.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/repositories/vehicle_repository.dart';

class InMemoryVehicleRepository implements VehicleRepository {
  InMemoryVehicleRepository({WorkshopStore? store}) : _store = store ?? WorkshopStore.instance;

  final WorkshopStore _store;

  @override
  Future<List<Vehicle>> all() async {
    return List.unmodifiable(_store.vehicles.reversed);
  }

  @override
  Future<Vehicle?> findById(int id) async {
    return _store.vehicles.where((item) => item.id == id).firstOrNull;
  }

  @override
  Future<Vehicle?> findByPlate(String plateKey) async {
    return _store.vehicles.where((item) => item.plateKey == plateKey).firstOrNull;
  }

  @override
  Future<Vehicle> save(VehicleDraft draft) async {
    return _store.saveVehicle(draft);
  }
}
