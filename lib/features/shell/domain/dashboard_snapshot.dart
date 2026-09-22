class DashboardSnapshot {
  const DashboardSnapshot({
    required this.unpaidTotal,
    required this.openJobs,
    required this.lowParts,
    required this.dueServiceCount,
    required this.todayAppointments,
  });

  final int unpaidTotal;
  final int openJobs;
  final int lowParts;
  final int dueServiceCount;
  final int todayAppointments;
}
