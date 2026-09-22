import '../../../../core/database/app_database.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';

class SqliteCustomerRepository implements CustomerRepository {
  @override
  Future<List<Customer>> all() async {
    final db = await AppDatabase.instance();
    final rows = await db.query('customers', orderBy: 'id DESC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Customer> upsert(CustomerDraft draft) async {
    final db = await AppDatabase.instance();
    final existing = await db.query('customers', where: 'phone = ?', whereArgs: [draft.phone], limit: 1);
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(
        'customers',
        {'name': draft.name, 'note': draft.note},
        where: 'id = ?',
        whereArgs: [id],
      );
      return Customer(id: id, name: draft.name, phone: draft.phone, note: draft.note);
    }
    final id = await db.insert('customers', {
      'name': draft.name,
      'phone': draft.phone,
      'note': draft.note,
    });
    return Customer(id: id, name: draft.name, phone: draft.phone, note: draft.note);
  }

  @override
  Future<List<Customer>> search(String query) async {
    final needle = query.trim();
    if (needle.isEmpty) {
      return all();
    }
    final db = await AppDatabase.instance();
    final rows = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$needle%', '%$needle%'],
    );
    return rows.map(_fromRow).toList();
  }

  Customer _fromRow(Map<String, Object?> row) {
    return Customer(
      id: row['id'] as int,
      name: row['name'] as String,
      phone: row['phone'] as String,
      note: row['note'] as String? ?? '',
    );
  }
}
