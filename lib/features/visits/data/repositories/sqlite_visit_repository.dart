import '../../../../core/database/app_database.dart';
import '../../domain/entities/service_visit.dart';
import '../../domain/repositories/visit_repository.dart';

class SqliteVisitRepository implements VisitRepository {
  @override
  Future<List<ServiceVisit>> all() async {
    final db = await AppDatabase.instance();
    final rows = await db.query('visits', orderBy: 'happened_at DESC');
    return _withLines(rows);
  }

  @override
  Future<List<ServiceVisit>> ofVehicle(int vehicleId) async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      'visits',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'happened_at DESC',
    );
    return _withLines(rows);
  }

  @override
  Future<ServiceVisit> save(VisitDraft draft) async {
    final db = await AppDatabase.instance();
    final lines = await _resolvedLines(draft);
    final partsAmount = lines.fold<int>(0, (sum, line) => sum + line.total);
    final laborAmount = draft.laborAmount;
    final amount = draft.amount > 0 ? draft.amount : laborAmount + partsAmount;
    final id = await db.insert('visits', {
      'vehicle_id': draft.vehicleId,
      'happened_at': draft.happenedAt.millisecondsSinceEpoch,
      'title': draft.title,
      'note': draft.note,
      'amount': amount,
      'labor_amount': laborAmount,
      'parts_amount': partsAmount > 0 ? partsAmount : draft.partsAmount,
      'paid': draft.paid ? 1 : 0,
      'part_id': lines.where((line) => line.partId != null).firstOrNull?.partId,
    });
    for (final line in lines) {
      await db.insert('visit_parts', {
        'visit_id': id,
        'part_id': line.partId,
        'name': line.name,
        'qty': line.qty,
        'unit_price': line.unitPrice,
      });
      if (line.partId != null) {
        await db.rawUpdate(
          'UPDATE parts SET stock = MAX(stock - ?, 0) WHERE id = ?',
          [line.qty, line.partId],
        );
      }
    }
    return (await _findById(id))!;
  }

  @override
  Future<ServiceVisit?> findById(int id) => _findById(id);

  @override
  Future<ServiceVisit> update(int id, VisitDraft draft) async {
    final db = await AppDatabase.instance();
    final current = await _findById(id);
    if (current == null) {
      throw StateError('visit not found');
    }
    await _restoreStock(current);
    await db.delete('visit_parts', where: 'visit_id = ?', whereArgs: [id]);
    final lines = await _resolvedLines(draft);
    final partsAmount = lines.fold<int>(0, (sum, line) => sum + line.total);
    final laborAmount = draft.laborAmount;
    final amount = draft.amount > 0 ? draft.amount : laborAmount + partsAmount;
    await db.update(
      'visits',
      {
        'vehicle_id': draft.vehicleId,
        'happened_at': draft.happenedAt.millisecondsSinceEpoch,
        'title': draft.title,
        'note': draft.note,
        'amount': amount,
        'labor_amount': laborAmount,
        'parts_amount': partsAmount > 0 ? partsAmount : draft.partsAmount,
        'paid': draft.paid ? 1 : 0,
        'part_id': lines.where((line) => line.partId != null).firstOrNull?.partId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    for (final line in lines) {
      await db.insert('visit_parts', {
        'visit_id': id,
        'part_id': line.partId,
        'name': line.name,
        'qty': line.qty,
        'unit_price': line.unitPrice,
      });
      if (line.partId != null) {
        await db.rawUpdate(
          'UPDATE parts SET stock = MAX(stock - ?, 0) WHERE id = ?',
          [line.qty, line.partId],
        );
      }
    }
    return (await _findById(id))!;
  }

  @override
  Future<void> setPaid(int id, bool paid) async {
    final db = await AppDatabase.instance();
    await db.update('visits', {'paid': paid ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> delete(int id) async {
    final db = await AppDatabase.instance();
    final visit = await _findById(id);
    if (visit == null) {
      return;
    }
    await _restoreStock(visit);
    await db.delete('visit_parts', where: 'visit_id = ?', whereArgs: [id]);
    await db.delete('visits', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _restoreStock(ServiceVisit visit) async {
    final db = await AppDatabase.instance();
    if (visit.partLines.isNotEmpty) {
      for (final line in visit.partLines) {
        if (line.partId != null) {
          await db.rawUpdate('UPDATE parts SET stock = stock + ? WHERE id = ?', [line.qty, line.partId]);
        }
      }
    } else if (visit.partId != null) {
      await db.rawUpdate('UPDATE parts SET stock = stock + 1 WHERE id = ?', [visit.partId]);
    }
  }

  @override
  Future<int> totalAmountOf(int vehicleId) async {
    final db = await AppDatabase.instance();
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM visits WHERE vehicle_id = ?',
      [vehicleId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  @override
  Future<int> unpaidAmountOfPhone(String phone) async {
    final db = await AppDatabase.instance();
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(visits.amount), 0) AS total
      FROM visits
      INNER JOIN vehicles ON vehicles.id = visits.vehicle_id
      WHERE vehicles.owner_phone = ? AND visits.paid = 0
      ''',
      [phone],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<ServiceVisit?> _findById(int id) async {
    final db = await AppDatabase.instance();
    final rows = await db.query('visits', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    final visits = await _withLines(rows);
    return visits.first;
  }

  Future<List<VisitPartLine>> _resolvedLines(VisitDraft draft) async {
    if (draft.partLines.isNotEmpty) {
      return draft.partLines;
    }
    if (draft.partId == null) {
      return const [];
    }
    final db = await AppDatabase.instance();
    final parts = await db.query('parts', columns: ['name', 'sell_price'], where: 'id = ?', whereArgs: [draft.partId], limit: 1);
    final name = parts.isEmpty ? 'قطعه' : parts.first['name'] as String;
    final price = draft.partsAmount > 0
        ? draft.partsAmount
        : (parts.isEmpty ? 0 : parts.first['sell_price'] as int);
    return [VisitPartLine(partId: draft.partId, name: name, qty: 1, unitPrice: price)];
  }

  Future<List<ServiceVisit>> _withLines(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) {
      return const [];
    }
    final db = await AppDatabase.instance();
    final ids = rows.map((row) => row['id'] as int).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final lineRows = await db.query(
      'visit_parts',
      where: 'visit_id IN ($placeholders)',
      whereArgs: ids,
    );
    final grouped = <int, List<VisitPartLine>>{};
    for (final row in lineRows) {
      final visitId = row['visit_id'] as int;
      grouped.putIfAbsent(visitId, () => []).add(
            VisitPartLine(
              partId: row['part_id'] as int?,
              name: row['name'] as String,
              qty: row['qty'] as int? ?? 1,
              unitPrice: row['unit_price'] as int? ?? 0,
            ),
          );
    }
    return rows.map((row) {
      final visit = _fromRow(row);
      return ServiceVisit(
        id: visit.id,
        vehicleId: visit.vehicleId,
        happenedAt: visit.happenedAt,
        title: visit.title,
        note: visit.note,
        amount: visit.amount,
        laborAmount: visit.laborAmount,
        partsAmount: visit.partsAmount,
        paid: visit.paid,
        partId: visit.partId,
        partLines: grouped[visit.id] ?? const [],
      );
    }).toList();
  }

  ServiceVisit _fromRow(Map<String, Object?> row) {
    return ServiceVisit(
      id: row['id'] as int,
      vehicleId: row['vehicle_id'] as int,
      happenedAt: DateTime.fromMillisecondsSinceEpoch(row['happened_at'] as int),
      title: row['title'] as String,
      note: row['note'] as String,
      amount: row['amount'] as int,
      laborAmount: row['labor_amount'] as int? ?? 0,
      partsAmount: row['parts_amount'] as int? ?? 0,
      paid: (row['paid'] as int? ?? 0) == 1,
      partId: row['part_id'] as int?,
    );
  }
}
