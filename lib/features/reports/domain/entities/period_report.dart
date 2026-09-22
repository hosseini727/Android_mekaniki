enum ReportPeriod {
  today,
  week,
  month,
  year,
  all;

  String get labelFa => switch (this) {
        today => 'امروز',
        week => 'این هفته',
        month => 'این ماه',
        year => 'امسال',
        all => 'همه',
      };
}

class DateSpan {
  const DateSpan({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;

  bool contains(DateTime value) {
    return !value.isBefore(start) && value.isBefore(endExclusive);
  }
}

class RankedLine {
  const RankedLine({
    required this.label,
    required this.amount,
    this.count = 0,
  });

  final String label;
  final int amount;
  final int count;
}

class TrendPoint {
  const TrendPoint({required this.label, required this.amount, required this.at});

  final String label;
  final int amount;
  final DateTime at;
}

class PeriodReport {
  const PeriodReport({
    required this.period,
    required this.span,
    required this.sales,
    required this.labor,
    required this.parts,
    required this.paid,
    required this.unpaid,
    required this.visitCount,
    required this.paidCount,
    required this.partsMargin,
    required this.previousSales,
    required this.trend,
    required this.topJobs,
    required this.topParts,
    required this.topCustomers,
    required this.insights,
  });

  final ReportPeriod period;
  final DateSpan span;
  final int sales;
  final int labor;
  final int parts;
  final int paid;
  final int unpaid;
  final int visitCount;
  final int paidCount;
  final int partsMargin;
  final int previousSales;
  final List<TrendPoint> trend;
  final List<RankedLine> topJobs;
  final List<RankedLine> topParts;
  final List<RankedLine> topCustomers;
  final List<String> insights;

  int get averageTicket => visitCount == 0 ? 0 : sales ~/ visitCount;

  int get salesDelta {
    if (previousSales == 0) {
      return sales == 0 ? 0 : 100;
    }
    return (((sales - previousSales) / previousSales) * 100).round();
  }

  double get laborShare => sales == 0 ? 0 : labor / sales;

  double get collectionRate => sales == 0 ? 0 : paid / sales;
}
