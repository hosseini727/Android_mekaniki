import '../../../../app/data/workshop_store.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';

class InMemoryCustomerRepository implements CustomerRepository {
  InMemoryCustomerRepository({WorkshopStore? store}) : _store = store ?? WorkshopStore.instance;

  final WorkshopStore _store;

  @override
  Future<List<Customer>> all() async => List.unmodifiable(_store.customers);

  @override
  Future<Customer> upsert(CustomerDraft draft) async => _store.upsertCustomer(draft);

  @override
  Future<List<Customer>> search(String query) async {
    final needle = query.trim();
    if (needle.isEmpty) {
      return all();
    }
    return _store.customers
        .where((item) => item.name.contains(needle) || item.phone.contains(needle))
        .toList();
  }
}
