import 'package:flutter/material.dart';

enum AppointmentStatus {
  booked,
  arrived,
  done;

  String get labelFa => switch (this) {
        booked => 'رزرو',
        arrived => 'وارد شد',
        done => 'انجام شد',
      };

  Color get color => switch (this) {
        booked => const Color(0xFFE8C07D),
        arrived => const Color(0xFF2DD4BF),
        done => const Color(0xFF86E3CE),
      };

  static AppointmentStatus fromName(String raw) {
    return AppointmentStatus.values.firstWhere(
      (item) => item.name == raw,
      orElse: () => AppointmentStatus.booked,
    );
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.customerName,
    required this.plateText,
    required this.scheduledAt,
    required this.bay,
    required this.status,
    this.note = '',
    this.vehicleId,
  });

  final int id;
  final int? vehicleId;
  final String customerName;
  final String plateText;
  final DateTime scheduledAt;
  final int bay;
  final String note;
  final AppointmentStatus status;
}

class AppointmentDraft {
  const AppointmentDraft({
    required this.customerName,
    required this.plateText,
    required this.scheduledAt,
    required this.bay,
    this.note = '',
    this.vehicleId,
    this.status = AppointmentStatus.booked,
  });

  final int? vehicleId;
  final String customerName;
  final String plateText;
  final DateTime scheduledAt;
  final int bay;
  final String note;
  final AppointmentStatus status;
}
