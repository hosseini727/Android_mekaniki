import 'package:flutter/material.dart';

import '../../app/router/app_routes.dart';

enum AppModule {
  intake,
  jobs,
  invoices,
  vehicles,
  voice,
  parts,
  customers,
  schedule,
  reports,
  settings,
}

class AppModuleDef {
  const AppModuleDef({
    required this.module,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.color,
  });

  final AppModule module;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
}

const appModules = <AppModuleDef>[
  AppModuleDef(
    module: AppModule.intake,
    title: 'پذیرش پلاک',
    subtitle: 'ورود پلاک با تایپ یا صدا و باز کردن پرونده',
    icon: Icons.center_focus_strong_rounded,
    route: AppRoutes.intake,
    color: Color(0xFF2DD4BF),
  ),
  AppModuleDef(
    module: AppModule.jobs,
    title: 'دستور کار',
    subtitle: 'سفارش تعمیر از پذیرش تا تحویل',
    icon: Icons.handyman_rounded,
    route: AppRoutes.jobs,
    color: Color(0xFF7EB6FF),
  ),
  AppModuleDef(
    module: AppModule.invoices,
    title: 'صورتحساب‌ها',
    subtitle: 'اجرت و قطعه روی کارهای ثبت‌شده — بدون فاکتور رسمی',
    icon: Icons.receipt_long_rounded,
    route: AppRoutes.invoices,
    color: Color(0xFFE8C07D),
  ),
  AppModuleDef(
    module: AppModule.vehicles,
    title: 'تاریخچه خودرو',
    subtitle: 'همه مراجعات، قطعات مصرفی و سرویس‌ها',
    icon: Icons.directions_car_filled_rounded,
    route: AppRoutes.vehicles,
    color: Color(0xFF7EB6FF),
  ),
  AppModuleDef(
    module: AppModule.voice,
    title: 'ثبت صوتی فاکتور',
    subtitle: 'با صدا بگو؛ پیش‌فاکتور ساخته می‌شود',
    icon: Icons.mic_rounded,
    route: AppRoutes.voice,
    color: Color(0xFF6366F1),
  ),
  AppModuleDef(
    module: AppModule.parts,
    title: 'قطعات و انبار',
    subtitle: 'موجودی، مصرف روی ماشین، خرید',
    icon: Icons.inventory_2_rounded,
    route: AppRoutes.parts,
    color: Color(0xFF9B8CFF),
  ),
  AppModuleDef(
    module: AppModule.customers,
    title: 'مشتریان',
    subtitle: 'مالک، شماره تماس، چند خودرو',
    icon: Icons.groups_rounded,
    route: AppRoutes.customers,
    color: Color(0xFF86E3CE),
  ),
  AppModuleDef(
    module: AppModule.schedule,
    title: 'نوبت و چاله',
    subtitle: 'ظرفیت تعمیرگاه و زمان‌بندی',
    icon: Icons.calendar_month_rounded,
    route: AppRoutes.schedule,
    color: Color(0xFFF0A500),
  ),
  AppModuleDef(
    module: AppModule.reports,
    title: 'گزارش‌ها',
    subtitle: 'فروش روز، حاشیه قطعه، عملکرد',
    icon: Icons.insights_rounded,
    route: AppRoutes.reports,
    color: Color(0xFF5AD1E6),
  ),
  AppModuleDef(
    module: AppModule.settings,
    title: 'تنظیمات کارگاه',
    subtitle: 'نام کارگاه، تماس و اطلاعات فروشگاه',
    icon: Icons.tune_rounded,
    route: AppRoutes.settings,
    color: Color(0xFF64748B),
  ),
];
