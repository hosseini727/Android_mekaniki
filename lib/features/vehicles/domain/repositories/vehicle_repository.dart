import '../entities/vehicle.dart';

abstract class VehicleRepository {
  Future<Vehicle?> findByPlate(String plateKey);
  Future<Vehicle?> findById(int id);
  Future<List<Vehicle>> all();
  Future<Vehicle> save(VehicleDraft draft);
}

class VehicleDraft {
  const VehicleDraft({
    required this.plateKey,
    required this.ownerName,
    required this.ownerPhone,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.mileage,
    this.platePhotoPath,
    this.vin = '',
    this.nextServiceKm = 0,
  });

  final String plateKey;
  final String ownerName;
  final String ownerPhone;
  final String make;
  final String model;
  final String year;
  final String color;
  final int mileage;
  final String? platePhotoPath;
  final String vin;
  final int nextServiceKm;
}
