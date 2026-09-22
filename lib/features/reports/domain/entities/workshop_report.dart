class WorkshopReport {
  const WorkshopReport({
    required this.totalSales,
    required this.laborTotal,
    required this.partsTotal,
    required this.visitCount,
    required this.vehicleCount,
    required this.openJobs,
    required this.openAppointments,
    required this.lowParts,
    required this.unpaidTotal,
    required this.dueServiceCount,
  });

  final int totalSales;
  final int laborTotal;
  final int partsTotal;
  final int visitCount;
  final int vehicleCount;
  final int openJobs;
  final int openAppointments;
  final int lowParts;
  final int unpaidTotal;
  final int dueServiceCount;
}
