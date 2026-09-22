import '../entities/part_item.dart';

abstract class PartRepository {
  Future<List<PartItem>> all();
  Future<PartItem> save(PartDraft draft, {int? id});
  Future<void> consume(int id, {int qty = 1});
}
