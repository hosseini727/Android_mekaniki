import '../../../../app/data/workshop_store.dart';
import '../../domain/entities/part_item.dart';
import '../../domain/repositories/part_repository.dart';

class InMemoryPartRepository implements PartRepository {
  InMemoryPartRepository({WorkshopStore? store}) : _store = store ?? WorkshopStore.instance;

  final WorkshopStore _store;

  @override
  Future<List<PartItem>> all() async => List.unmodifiable(_store.parts);

  @override
  Future<PartItem> save(PartDraft draft, {int? id}) async => _store.savePart(draft, id: id);

  @override
  Future<void> consume(int id, {int qty = 1}) async {
    _store.consumePart(id, qty: qty);
  }
}
