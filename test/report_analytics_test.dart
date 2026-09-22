import 'package:flutter_test/flutter_test.dart';
import 'package:kargah_yar/features/parts/domain/entities/part_item.dart';
import 'package:kargah_yar/features/reports/domain/entities/period_report.dart';
import 'package:kargah_yar/features/reports/domain/report_analytics.dart';
import 'package:kargah_yar/features/vehicles/domain/entities/vehicle.dart';
import 'package:kargah_yar/features/visits/domain/entities/service_visit.dart';

void main() {
  final vehicle = Vehicle(
    id: 1,
    plateKey: '12ب34522',
    ownerName: 'علی رضایی',
    ownerPhone: '09121234567',
    make: 'پژو',
    model: 'پارس',
    year: '1398',
    color: 'سفید',
    mileage: 100000,
  );

  final oil = const PartItem(
    id: 8,
    name: 'روغن موتور',
    stock: 10,
    buyPrice: 200000,
    sellPrice: 350000,
  );

  test('month report totals current span and compares with previous', () {
    final now = DateTime(2026, 8, 17);
    final span = ReportAnalytics.spanFor(ReportPeriod.month, now: now);
    final previous = ReportAnalytics.previousSpan(span);
    final report = ReportAnalytics.build(
      period: ReportPeriod.month,
      now: now,
      vehicles: [vehicle],
      parts: [oil],
      visits: [
        ServiceVisit(
          id: 1,
          vehicleId: 1,
          happenedAt: span.start.add(const Duration(days: 2)),
          title: 'لنت ترمز',
          note: '',
          amount: 2000000,
          laborAmount: 500000,
          partsAmount: 1500000,
          paid: true,
          partLines: [
            VisitPartLine(partId: oil.id, name: oil.name, qty: 1, unitPrice: 350000),
          ],
        ),
        ServiceVisit(
          id: 2,
          vehicleId: 1,
          happenedAt: previous.start.add(const Duration(days: 1)),
          title: 'باتری',
          note: '',
          amount: 1000000,
          laborAmount: 200000,
          partsAmount: 800000,
          paid: false,
        ),
      ],
    );

    expect(report.sales, 2000000);
    expect(report.labor, 500000);
    expect(report.visitCount, 1);
    expect(report.previousSales, 1000000);
    expect(report.salesDelta, 100);
    expect(report.paid, 2000000);
    expect(report.unpaid, 0);
    expect(report.topJobs.first.label, 'لنت ترمز');
    expect(report.topCustomers.first.label, 'علی رضایی');
    expect(report.partsMargin, 150000);
    expect(report.insights, isNotEmpty);
  });

  test('persian week starts on saturday', () {
    final wednesday = DateTime(2026, 8, 19);
    final span = ReportAnalytics.spanFor(ReportPeriod.week, now: wednesday);
    expect(span.start.weekday, DateTime.saturday);
    expect(span.endExclusive.difference(span.start).inDays, 7);
  });
}
