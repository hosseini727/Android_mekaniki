import '../entities/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> all();
  Future<Customer> upsert(CustomerDraft draft);
  Future<List<Customer>> search(String query);
}
