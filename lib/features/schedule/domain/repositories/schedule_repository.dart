import '../entities/appointment.dart';

abstract class ScheduleRepository {
  Future<List<Appointment>> all();
  Future<Appointment> save(AppointmentDraft draft);
  Future<Appointment> updateStatus(int id, AppointmentStatus status);
}
