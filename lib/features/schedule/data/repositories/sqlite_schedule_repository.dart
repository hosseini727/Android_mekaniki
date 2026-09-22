import '../../../../core/database/app_database.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/schedule_repository.dart';

class SqliteScheduleRepository implements ScheduleRepository {
  @override
  Future<List<Appointment>> all() async {
    final db = await AppDatabase.instance();
    final rows = await db.query('appointments', orderBy: 'scheduled_at ASC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Appointment> save(AppointmentDraft draft) async {
    final db = await AppDatabase.instance();
    final id = await db.insert('appointments', {
      'vehicle_id': draft.vehicleId,
      'customer_name': draft.customerName,
      'plate_text': draft.plateText,
      'scheduled_at': draft.scheduledAt.millisecondsSinceEpoch,
      'bay': draft.bay,
      'note': draft.note,
      'status': draft.status.name,
    });
    return Appointment(
      id: id,
      vehicleId: draft.vehicleId,
      customerName: draft.customerName,
      plateText: draft.plateText,
      scheduledAt: draft.scheduledAt,
      bay: draft.bay,
      note: draft.note,
      status: draft.status,
    );
  }

  @override
  Future<Appointment> updateStatus(int id, AppointmentStatus status) async {
    final db = await AppDatabase.instance();
    await db.update('appointments', {'status': status.name}, where: 'id = ?', whereArgs: [id]);
    final rows = await db.query('appointments', where: 'id = ?', whereArgs: [id], limit: 1);
    return _fromRow(rows.first);
  }

  Appointment _fromRow(Map<String, Object?> row) {
    return Appointment(
      id: row['id'] as int,
      vehicleId: row['vehicle_id'] as int?,
      customerName: row['customer_name'] as String,
      plateText: row['plate_text'] as String,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(row['scheduled_at'] as int),
      bay: row['bay'] as int,
      note: row['note'] as String,
      status: AppointmentStatus.fromName(row['status'] as String),
    );
  }
}
