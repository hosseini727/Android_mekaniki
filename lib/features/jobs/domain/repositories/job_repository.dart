import '../entities/repair_job.dart';

abstract class JobRepository {
  Future<List<RepairJob>> all();
  Future<RepairJob> save(JobDraft draft);
  Future<RepairJob> updateStatus(int id, JobStatus status);
}
