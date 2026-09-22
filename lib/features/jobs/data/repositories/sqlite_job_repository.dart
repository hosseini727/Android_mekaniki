import '../../../../core/database/app_database.dart';
import '../../domain/entities/repair_job.dart';
import '../../domain/repositories/job_repository.dart';

class SqliteJobRepository implements JobRepository {
  @override
  Future<List<RepairJob>> all() async {
    final db = await AppDatabase.instance();
    final rows = await db.rawQuery('''
      SELECT jobs.*, vehicles.make, vehicles.model, vehicles.plate_key, vehicles.owner_name
      FROM jobs
      LEFT JOIN vehicles ON vehicles.id = jobs.vehicle_id
      ORDER BY jobs.created_at DESC
    ''');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<RepairJob> save(JobDraft draft) async {
    final db = await AppDatabase.instance();
    final id = await db.insert('jobs', {
      'vehicle_id': draft.vehicleId,
      'title': draft.title,
      'note': draft.note,
      'status': draft.status.name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    final rows = await db.rawQuery('''
      SELECT jobs.*, vehicles.make, vehicles.model, vehicles.plate_key, vehicles.owner_name
      FROM jobs
      LEFT JOIN vehicles ON vehicles.id = jobs.vehicle_id
      WHERE jobs.id = ?
    ''', [id]);
    return _fromRow(rows.first);
  }

  @override
  Future<RepairJob> updateStatus(int id, JobStatus status) async {
    final db = await AppDatabase.instance();
    await db.update('jobs', {'status': status.name}, where: 'id = ?', whereArgs: [id]);
    final rows = await db.rawQuery('''
      SELECT jobs.*, vehicles.make, vehicles.model, vehicles.plate_key, vehicles.owner_name
      FROM jobs
      LEFT JOIN vehicles ON vehicles.id = jobs.vehicle_id
      WHERE jobs.id = ?
    ''', [id]);
    return _fromRow(rows.first);
  }

  RepairJob _fromRow(Map<String, Object?> row) {
    final make = row['make'] as String? ?? '';
    final model = row['model'] as String? ?? '';
    return RepairJob(
      id: row['id'] as int,
      vehicleId: row['vehicle_id'] as int,
      title: row['title'] as String,
      note: row['note'] as String,
      status: JobStatus.fromName(row['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      vehicleTitle: '$make $model'.trim(),
      plateKey: row['plate_key'] as String? ?? '',
      ownerName: row['owner_name'] as String? ?? '',
    );
  }
}
