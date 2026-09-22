class ServiceVisit {
  const ServiceVisit({
    required this.id,
    required this.vehicleId,
    required this.happenedAt,
    required this.title,
    required this.note,
    required this.amount,
    this.laborAmount = 0,
    this.partsAmount = 0,
    this.paid = false,
    this.partId,
    this.partLines = const [],
  });

  final int id;
  final int vehicleId;
  final DateTime happenedAt;
  final String title;
  final String note;
  final int amount;
  final int laborAmount;
  final int partsAmount;
  final bool paid;
  final int? partId;
  final List<VisitPartLine> partLines;

  bool get hasBreakdown => laborAmount > 0 || partsAmount > 0;
}

class VisitPartLine {
  const VisitPartLine({
    this.partId,
    required this.name,
    this.qty = 1,
    required this.unitPrice,
  });

  final int? partId;
  final String name;
  final int qty;
  final int unitPrice;

  int get total => qty * unitPrice;
}
