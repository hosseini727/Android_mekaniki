import 'package:flutter_test/flutter_test.dart';
import 'package:kargah_yar/app/data/workshop_store.dart';
import 'package:kargah_yar/features/parts/domain/entities/part_item.dart';
import 'package:kargah_yar/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:kargah_yar/features/visits/data/repositories/in_memory_visit_repository.dart';
import 'package:kargah_yar/features/visits/domain/entities/service_visit.dart';
import 'package:kargah_yar/features/visits/domain/repositories/visit_repository.dart';

WorkshopStore _storeWithParts() {
  final store = WorkshopStore();
  store.savePart(const PartDraft(name: 'روغن ۱۰W۴۰', sku: 'OIL-10W40', stock: 12, buyPrice: 280000, sellPrice: 350000));
  store.savePart(const PartDraft(name: 'فیلتر روغن', sku: 'FLT-OIL', stock: 20, buyPrice: 90000, sellPrice: 140000));
  store.savePart(const PartDraft(name: 'شمع NGK', sku: 'SPK-NGK', stock: 16, buyPrice: 180000, sellPrice: 280000));
  return store;
}

void main() {
  test('saves and lists visits for a vehicle', () async {
    final repo = InMemoryVisitRepository(store: WorkshopStore());
    final saved = await repo.save(
      VisitDraft(
        vehicleId: 99,
        happenedAt: DateTime(2026, 8, 17),
        title: 'تعویض شمع',
        note: 'شمع NGK + وایر',
        amount: 1200000,
        laborAmount: 300000,
        partsAmount: 900000,
      ),
    );

    expect(saved.id, greaterThan(0));
    expect(saved.title, 'تعویض شمع');

    final visits = await repo.ofVehicle(99);
    expect(visits, hasLength(1));
    expect(visits.first.amount, 1200000);

    final total = await repo.totalAmountOf(99);
    expect(total, 1200000);
  });

  test('deletes a visit from history', () async {
    final repo = InMemoryVisitRepository(store: WorkshopStore());
    final saved = await repo.save(
      VisitDraft(
        vehicleId: 7,
        happenedAt: DateTime(2026, 8, 17),
        title: 'تعویض روغن',
        note: '',
        amount: 800000,
      ),
    );
    expect(await repo.ofVehicle(7), hasLength(1));
    await repo.delete(saved.id);
    expect(await repo.ofVehicle(7), isEmpty);
    expect(await repo.totalAmountOf(7), 0);
  });

  test('tracks unpaid debt for an owner phone', () async {
    final store = WorkshopStore();
    store.saveVehicle(
      const VehicleDraft(
        plateKey: '12ب34522',
        ownerName: 'علی رضایی',
        ownerPhone: '09121234567',
        make: 'پژو',
        model: 'پارس',
        year: '1398',
        color: 'سفید',
        mileage: 0,
      ),
    );
    final repo = InMemoryVisitRepository(store: store);
    await repo.save(
      VisitDraft(
        vehicleId: 1,
        happenedAt: DateTime(2026, 5, 12),
        title: 'سرویس',
        note: '',
        amount: 1000000,
        paid: true,
      ),
    );
    final unpaid = await repo.save(
      VisitDraft(
        vehicleId: 1,
        happenedAt: DateTime(2026, 1, 8),
        title: 'لنت',
        note: '',
        amount: 4200000,
        paid: false,
      ),
    );
    expect(await repo.unpaidAmountOfPhone('09121234567'), 4200000);
    await repo.setPaid(unpaid.id, true);
    expect(await repo.unpaidAmountOfPhone('09121234567'), 0);
  });

  test('saves several parts and restores stock on delete', () async {
    final store = _storeWithParts();
    final oil = store.parts.firstWhere((item) => item.sku == 'OIL-10W40');
    final filter = store.parts.firstWhere((item) => item.sku == 'FLT-OIL');
    final oilStock = oil.stock;
    final filterStock = filter.stock;
    final repo = InMemoryVisitRepository(store: store);
    final saved = await repo.save(
      VisitDraft(
        vehicleId: 1,
        happenedAt: DateTime(2026, 8, 17),
        title: 'سرویس روغن',
        note: '',
        amount: 0,
        laborAmount: 450000,
        partLines: [
          VisitPartLine(partId: oil.id, name: oil.name, qty: 1, unitPrice: oil.sellPrice),
          VisitPartLine(partId: filter.id, name: filter.name, qty: 2, unitPrice: filter.sellPrice),
        ],
      ),
    );

    expect(saved.laborAmount, 450000);
    expect(saved.partLines, hasLength(2));
    expect(saved.partsAmount, oil.sellPrice + (filter.sellPrice * 2));
    expect(saved.amount, saved.laborAmount + saved.partsAmount);
    expect(store.parts.firstWhere((item) => item.id == oil.id).stock, oilStock - 1);
    expect(store.parts.firstWhere((item) => item.id == filter.id).stock, filterStock - 2);

    await repo.delete(saved.id);
    expect(store.parts.firstWhere((item) => item.id == oil.id).stock, oilStock);
    expect(store.parts.firstWhere((item) => item.id == filter.id).stock, filterStock);
  });

  test('updates a visit and adjusts stock', () async {
    final store = _storeWithParts();
    final oil = store.parts.firstWhere((item) => item.sku == 'OIL-10W40');
    final spark = store.parts.firstWhere((item) => item.sku == 'SPK-NGK');
    final oilStock = oil.stock;
    final sparkStock = spark.stock;
    final repo = InMemoryVisitRepository(store: store);
    final saved = await repo.save(
      VisitDraft(
        vehicleId: 1,
        happenedAt: DateTime(2026, 8, 17),
        title: 'روغن',
        note: '',
        amount: 0,
        laborAmount: 400000,
        partLines: [
          VisitPartLine(partId: oil.id, name: oil.name, qty: 1, unitPrice: oil.sellPrice),
        ],
      ),
    );
    expect(store.parts.firstWhere((item) => item.id == oil.id).stock, oilStock - 1);

    final updated = await repo.update(
      saved.id,
      VisitDraft(
        vehicleId: 1,
        happenedAt: DateTime(2026, 8, 18),
        title: 'شمع',
        note: 'ویرایش شد',
        amount: 0,
        laborAmount: 500000,
        paid: true,
        partLines: [
          VisitPartLine(partId: spark.id, name: spark.name, qty: 2, unitPrice: spark.sellPrice),
        ],
      ),
    );

    expect(updated.title, 'شمع');
    expect(updated.laborAmount, 500000);
    expect(updated.paid, isTrue);
    expect(updated.partLines, hasLength(1));
    expect(store.parts.firstWhere((item) => item.id == oil.id).stock, oilStock);
    expect(store.parts.firstWhere((item) => item.id == spark.id).stock, sparkStock - 2);
  });
}
