import '../../../../core/database/app_database.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';

class SqliteVehicleRepository implements VehicleRepository {
  @override
  Future<List<Vehicle>> all() async {
    final db = await AppDatabase.instance();
    final rows = await db.query('vehicles', orderBy: 'id DESC');
    return rows.map(_vehicle).toList();
  }

  @override
  Future<Vehicle?> findById(int id) async {
    final db = await AppDatabase.instance();
    final rows = await db.query('vehicles', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    return _vehicle(rows.first);
  }

  @override
  Future<Vehicle?> findByPlate(String plateKey) async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      'vehicles',
      where: 'plate_key = ?',
      whereArgs: [plateKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _vehicle(rows.first);
  }

  @override
  Future<Vehicle> save(VehicleDraft draft) async {
    final db = await AppDatabase.instance();
    final existing = await db.query('customers', where: 'phone = ?', whereArgs: [draft.ownerPhone], limit: 1);
    if (existing.isEmpty) {
      await db.insert('customers', {
        'name': draft.ownerName,
        'phone': draft.ownerPhone,
        'note': '',
      });
    } else if (draft.ownerName.isNotEmpty) {
      await db.update(
        'customers',
        {'name': draft.ownerName},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
    final id = await db.insert('vehicles', {
      'plate_key': draft.plateKey,
      'owner_name': draft.ownerName,
      'owner_phone': draft.ownerPhone,
      'make': draft.make,
      'model': draft.model,
      'year': draft.year,
      'color': draft.color,
      'mileage': draft.mileage,
      'plate_photo_path': draft.platePhotoPath,
      'vin': draft.vin,
      'next_service_km': draft.nextServiceKm,
    });
    return (await findById(id))!;
  }

  Vehicle _vehicle(Map<String, Object?> row) {
    return Vehicle(
      id: row['id'] as int,
      plateKey: row['plate_key'] as String,
      ownerName: row['owner_name'] as String,
      ownerPhone: row['owner_phone'] as String,
      make: row['make'] as String,
      model: row['model'] as String,
      year: row['year'] as String,
      color: row['color'] as String,
      mileage: row['mileage'] as int,
      platePhotoPath: row['plate_photo_path'] as String?,
      vin: row['vin'] as String? ?? '',
      nextServiceKm: row['next_service_km'] as int? ?? 0,
    );
  }
}
