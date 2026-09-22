import 'package:shamsi_date/shamsi_date.dart';

import '../../../core/utils/money_format.dart';
import '../../../core/utils/shamsi_format.dart';
import '../../parts/domain/entities/part_item.dart';
import '../../vehicles/domain/entities/vehicle.dart';
import '../../visits/domain/entities/service_visit.dart';
import 'entities/period_report.dart';

class ReportAnalytics {
  ReportAnalytics._();

  static DateSpan spanFor(ReportPeriod period, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final jalali = Jalali.fromDateTime(today);
    switch (period) {
      case ReportPeriod.today:
        return DateSpan(start: today, endExclusive: today.add(const Duration(days: 1)));
      case ReportPeriod.week:
        final fromSaturday = (today.weekday + 1) % 7;
        final start = today.subtract(Duration(days: fromSaturday));
        return DateSpan(start: start, endExclusive: start.add(const Duration(days: 7)));
      case ReportPeriod.month:
        final start = Jalali(jalali.year, jalali.month, 1).toDateTime();
        final nextMonth = jalali.month == 12 ? Jalali(jalali.year + 1, 1, 1) : Jalali(jalali.year, jalali.month + 1, 1);
        return DateSpan(start: start, endExclusive: nextMonth.toDateTime());
      case ReportPeriod.year:
        final start = Jalali(jalali.year, 1, 1).toDateTime();
        final next = Jalali(jalali.year + 1, 1, 1).toDateTime();
        return DateSpan(start: start, endExclusive: next);
      case ReportPeriod.all:
        return DateSpan(start: DateTime(2001, 3, 21), endExclusive: today.add(const Duration(days: 1)));
    }
  }

  static DateSpan previousSpan(DateSpan span) {
    final length = span.endExclusive.difference(span.start);
    return DateSpan(start: span.start.subtract(length), endExclusive: span.start);
  }

  static PeriodReport build({
    required ReportPeriod period,
    required List<ServiceVisit> visits,
    required List<Vehicle> vehicles,
    required List<PartItem> parts,
    DateTime? now,
  }) {
    final span = spanFor(period, now: now);
    final previous = previousSpan(span);
    final inRange = visits.where((item) => span.contains(item.happenedAt)).toList();
    final before = visits.where((item) => previous.contains(item.happenedAt)).toList();
    final byId = {for (final car in vehicles) car.id: car};
    final partById = {for (final part in parts) part.id: part};

    final sales = _sum(inRange, (item) => item.amount);
    final labor = _sum(inRange, (item) => item.laborAmount);
    final partsTotal = _sum(inRange, (item) => item.partsAmount);
    final paid = _sum(inRange.where((item) => item.paid), (item) => item.amount);
    final unpaid = sales - paid;
    final previousSales = _sum(before, (item) => item.amount);
    final margin = _partsMargin(inRange, partById);
    final trend = _trend(period, span, inRange, now: now);
    final topJobs = _rankJobs(inRange);
    final topParts = _rankParts(inRange);
    final topCustomers = _rankCustomers(inRange, byId);
    final draft = PeriodReport(
      period: period,
      span: span,
      sales: sales,
      labor: labor,
      parts: partsTotal,
      paid: paid,
      unpaid: unpaid,
      visitCount: inRange.length,
      paidCount: inRange.where((item) => item.paid).length,
      partsMargin: margin,
      previousSales: previousSales,
      trend: trend,
      topJobs: topJobs,
      topParts: topParts,
      topCustomers: topCustomers,
      insights: const [],
    );
    return PeriodReport(
      period: draft.period,
      span: draft.span,
      sales: draft.sales,
      labor: draft.labor,
      parts: draft.parts,
      paid: draft.paid,
      unpaid: draft.unpaid,
      visitCount: draft.visitCount,
      paidCount: draft.paidCount,
      partsMargin: draft.partsMargin,
      previousSales: draft.previousSales,
      trend: draft.trend,
      topJobs: draft.topJobs,
      topParts: draft.topParts,
      topCustomers: draft.topCustomers,
      insights: _insights(draft),
    );
  }

  static int _sum(Iterable<ServiceVisit> items, int Function(ServiceVisit) read) {
    return items.fold<int>(0, (sum, item) => sum + read(item));
  }

  static int _partsMargin(List<ServiceVisit> visits, Map<int, PartItem> parts) {
    var total = 0;
    for (final visit in visits) {
      for (final line in visit.partLines) {
        final part = line.partId == null ? null : parts[line.partId];
        if (part == null || part.buyPrice <= 0) {
          continue;
        }
        total += (line.unitPrice - part.buyPrice) * line.qty;
      }
    }
    return total;
  }

  static List<TrendPoint> _trend(
    ReportPeriod period,
    DateSpan span,
    List<ServiceVisit> visits, {
    DateTime? now,
  }) {
    if (period == ReportPeriod.year || period == ReportPeriod.all) {
      return _monthlyTrend(period, visits, now: now);
    }
    return _dailyTrend(span, visits);
  }

  static List<TrendPoint> _monthlyTrend(ReportPeriod period, List<ServiceVisit> visits, {DateTime? now}) {
    final current = Jalali.fromDateTime(now ?? DateTime.now());
    final end = Jalali(current.year, current.month, 1);
    final start = period == ReportPeriod.year ? Jalali(current.year, 1, 1) : _shiftMonth(end, -11);
    final points = <TrendPoint>[];
    var cursor = start;
    while (true) {
      final begin = cursor.toDateTime();
      final next = _shiftMonth(cursor, 1);
      final close = next.toDateTime();
      final amount = visits
          .where((item) => !item.happenedAt.isBefore(begin) && item.happenedAt.isBefore(close))
          .fold<int>(0, (sum, item) => sum + item.amount);
      points.add(TrendPoint(label: ShamsiFormat.monthYear(begin), amount: amount, at: begin));
      if (cursor.year == end.year && cursor.month == end.month) {
        break;
      }
      cursor = next;
    }
    return points;
  }

  static Jalali _shiftMonth(Jalali month, int delta) {
    var year = month.year;
    var value = month.month + delta;
    while (value > 12) {
      value -= 12;
      year++;
    }
    while (value < 1) {
      value += 12;
      year--;
    }
    return Jalali(year, value, 1);
  }

  static List<TrendPoint> _dailyTrend(DateSpan span, List<ServiceVisit> visits) {
    final points = <TrendPoint>[];
    var day = DateTime(span.start.year, span.start.month, span.start.day);
    while (day.isBefore(span.endExclusive)) {
      final next = day.add(const Duration(days: 1));
      final amount = visits
          .where((item) => !item.happenedAt.isBefore(day) && item.happenedAt.isBefore(next))
          .fold<int>(0, (sum, item) => sum + item.amount);
      points.add(TrendPoint(label: ShamsiFormat.monthDay(day), amount: amount, at: day));
      day = next;
    }
    return points;
  }

  static List<RankedLine> _rankJobs(List<ServiceVisit> visits) {
    final map = <String, RankedLine>{};
    for (final visit in visits) {
      final key = visit.title.trim().isEmpty ? 'بدون عنوان' : visit.title.trim();
      final current = map[key];
      map[key] = RankedLine(
        label: key,
        amount: (current?.amount ?? 0) + visit.amount,
        count: (current?.count ?? 0) + 1,
      );
    }
    return _top(map.values);
  }

  static List<RankedLine> _rankParts(List<ServiceVisit> visits) {
    final map = <String, RankedLine>{};
    for (final visit in visits) {
      for (final line in visit.partLines) {
        final key = line.name.trim().isEmpty ? 'قطعه' : line.name.trim();
        final current = map[key];
        map[key] = RankedLine(
          label: key,
          amount: (current?.amount ?? 0) + line.total,
          count: (current?.count ?? 0) + line.qty,
        );
      }
    }
    return _top(map.values);
  }

  static List<RankedLine> _rankCustomers(List<ServiceVisit> visits, Map<int, Vehicle> vehicles) {
    final map = <String, RankedLine>{};
    for (final visit in visits) {
      final car = vehicles[visit.vehicleId];
      final key = car == null
          ? 'نامشخص'
          : (car.ownerName.trim().isEmpty ? car.plate.display : car.ownerName.trim());
      final current = map[key];
      map[key] = RankedLine(
        label: key,
        amount: (current?.amount ?? 0) + visit.amount,
        count: (current?.count ?? 0) + 1,
      );
    }
    return _top(map.values);
  }

  static List<RankedLine> _top(Iterable<RankedLine> items) {
    final list = items.toList()..sort((a, b) => b.amount.compareTo(a.amount));
    return list.take(5).toList();
  }

  static List<String> _insights(PeriodReport report) {
    final lines = <String>[];
    if (report.visitCount == 0) {
      return const ['در این بازه کاری ثبت نشده.'];
    }
    if (report.previousSales > 0) {
      final delta = report.salesDelta;
      if (delta > 0) {
        lines.add('فروش نسبت به بازه قبل $delta درصد بیشتر شده.');
      } else if (delta < 0) {
        lines.add('فروش نسبت به بازه قبل ${delta.abs()} درصد کمتر شده.');
      } else {
        lines.add('فروش با بازه قبل برابر است.');
      }
    }
    final laborPct = (report.laborShare * 100).round();
    lines.add('$laborPct درصد درآمد از اجرت و ${100 - laborPct} درصد از قطعه بوده.');
    if (report.unpaid > 0) {
      lines.add('${report.visitCount - report.paidCount} کار هنوز تسویه نشده؛ بدهی ${MoneyFormat.toman(report.unpaid)}.');
    } else {
      lines.add('همه کارهای این بازه تسویه شده‌اند.');
    }
    if (report.topJobs.isNotEmpty) {
      lines.add('پرتکرارترین کار: ${report.topJobs.first.label}.');
    }
    return lines.take(4).toList();
  }
}
