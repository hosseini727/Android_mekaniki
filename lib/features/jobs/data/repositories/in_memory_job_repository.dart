import '../../../../app/data/workshop_store.dart';
import '../../domain/entities/repair_job.dart';
import '../../domain/repositories/job_repository.dart';

class InMemoryJobRepository implements JobRepository {
  InMemoryJobRepository({WorkshopStore? store}) : _store = store ?? WorkshopStore.instance;

  final WorkshopStore _store;

  @override
  Future<List<RepairJob>> all() async {
    return _store.jobs.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<RepairJob> save(JobDraft draft) async => _store.saveJob(draft);

  @override
  Future<RepairJob> updateStatus(int id, JobStatus status) async => _store.updateJobStatus(id, status);
}
