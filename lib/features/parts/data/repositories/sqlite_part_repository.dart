import '../../../../core/database/app_database.dart';
import '../../domain/entities/part_item.dart';
import '../../domain/repositories/part_repository.dart';

class SqlitePartRepository implements PartRepository {
  @override
  Future<List<PartItem>> all() async {
    final db = await AppDatabase.instance();
    final rows = await db.query('parts', orderBy: 'id DESC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<PartItem> save(PartDraft draft, {int? id}) async {
    final db = await AppDatabase.instance();
    final payload = {
      'name': draft.name,
      'sku': draft.sku,
      'stock': draft.stock,
      'buy_price': draft.buyPrice,
      'sell_price': draft.sellPrice,
    };
    if (id != null) {
      await db.update('parts', payload, where: 'id = ?', whereArgs: [id]);
      return PartItem(
        id: id,
        name: draft.name,
        sku: draft.sku,
        stock: draft.stock,
        buyPrice: draft.buyPrice,
        sellPrice: draft.sellPrice,
      );
    }
    final newId = await db.insert('parts', payload);
    return PartItem(
      id: newId,
      name: draft.name,
      sku: draft.sku,
      stock: draft.stock,
      buyPrice: draft.buyPrice,
      sellPrice: draft.sellPrice,
    );
  }

  @override
  Future<void> consume(int id, {int qty = 1}) async {
    final db = await AppDatabase.instance();
    await db.rawUpdate('UPDATE parts SET stock = MAX(stock - ?, 0) WHERE id = ?', [qty, id]);
  }

  PartItem _fromRow(Map<String, Object?> row) {
    return PartItem(
      id: row['id'] as int,
      name: row['name'] as String,
      sku: row['sku'] as String,
      stock: row['stock'] as int,
      buyPrice: row['buy_price'] as int,
      sellPrice: row['sell_price'] as int,
    );
  }
}
