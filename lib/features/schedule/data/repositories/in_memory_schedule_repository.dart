import '../../../../app/data/workshop_store.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/schedule_repository.dart';

class InMemoryScheduleRepository implements ScheduleRepository {
  InMemoryScheduleRepository({WorkshopStore? store}) : _store = store ?? WorkshopStore.instance;

  final WorkshopStore _store;

  @override
  Future<List<Appointment>> all() async {
    return _store.appointments.toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  @override
  Future<Appointment> save(AppointmentDraft draft) async => _store.saveAppointment(draft);

  @override
  Future<Appointment> updateStatus(int id, AppointmentStatus status) async {
    return _store.updateAppointmentStatus(id, status);
  }
}
