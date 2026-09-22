import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum JobStatus {
  waiting,
  inProgress,
  done;

  String get labelFa => switch (this) {
        waiting => 'منتظر',
        inProgress => 'در حال کار',
        done => 'تمام',
      };

  Color get color => switch (this) {
        waiting => const Color(0xFFE8C07D),
        inProgress => AppColors.teal,
        done => const Color(0xFF86E3CE),
      };

  static JobStatus fromName(String raw) {
    return JobStatus.values.firstWhere(
      (item) => item.name == raw,
      orElse: () => JobStatus.waiting,
    );
  }
}

class RepairJob {
  const RepairJob({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.note,
    required this.status,
    required this.createdAt,
    this.vehicleTitle = '',
    this.plateKey = '',
    this.ownerName = '',
  });

  final int id;
  final int vehicleId;
  final String title;
  final String note;
  final JobStatus status;
  final DateTime createdAt;
  final String vehicleTitle;
  final String plateKey;
  final String ownerName;
}

class JobDraft {
  const JobDraft({
    required this.vehicleId,
    required this.title,
    this.note = '',
    this.status = JobStatus.waiting,
  });

  final int vehicleId;
  final String title;
  final String note;
  final JobStatus status;
}
