import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/shamsi_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/period_report.dart';
import '../../domain/entities/workshop_report.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportPeriod _period = ReportPeriod.month;

  @override
  Widget build(BuildContext context) {
    final periodAsync = ref.watch(periodReportProvider(_period));
    final healthAsync = ref.watch(reportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('گزارش‌ها')),
      body: periodAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('خطا در گزارش')),
        data: (report) {
          return RefreshIndicator(
            color: AppColors.copper,
            onRefresh: () async {
              ref.invalidate(periodReportProvider(_period));
              ref.invalidate(reportsProvider);
              await ref.read(periodReportProvider(_period).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const Text('گزارش عملکرد کارگاه', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  report.period == ReportPeriod.all
                      ? 'از اولین کار ثبت‌شده تا امروز'
                      : '${ShamsiFormat.numeric(report.span.start)}  تا  ${ShamsiFormat.numeric(report.span.endExclusive.subtract(const Duration(days: 1)))}',
                  style: const TextStyle(color: AppColors.muted, height: 1.6),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ReportPeriod.values.map((item) {
                    final selected = _period == item;
                    return FilterChip(
                      label: Text(item.labelFa),
                      selected: selected,
                      onSelected: (_) => setState(() => _period = item),
                      selectedColor: AppColors.copperSoft,
                      checkmarkColor: AppColors.copper,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.copper : AppColors.cream,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      side: BorderSide(color: selected ? AppColors.copper : AppColors.line),
                      backgroundColor: AppColors.surfaceHigh,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                _SalesHero(report: report),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _Kpi(label: 'اجرت', value: MoneyFormat.toman(report.labor), color: AppColors.teal)),
                    const SizedBox(width: 10),
                    Expanded(child: _Kpi(label: 'قطعه', value: MoneyFormat.toman(report.parts), color: AppColors.copper)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _Kpi(label: 'وصول‌شده', value: MoneyFormat.toman(report.paid), color: AppColors.teal)),
                    const SizedBox(width: 10),
                    Expanded(child: _Kpi(label: 'بدهی بازه', value: MoneyFormat.toman(report.unpaid), color: AppColors.danger)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _Kpi(label: 'تعداد کار', value: '${report.visitCount}', color: AppColors.cream)),
                    const SizedBox(width: 10),
                    Expanded(child: _Kpi(label: 'میانگین هر کار', value: MoneyFormat.toman(report.averageTicket), color: AppColors.copper)),
                  ],
                ),
                if (report.partsMargin != 0) ...[
                  const SizedBox(height: 10),
                  _Kpi(label: 'سود تقریبی قطعه', value: MoneyFormat.toman(report.partsMargin), color: AppColors.teal),
                ],
                const SizedBox(height: 18),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ترکیب درآمد', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(
                        'نرخ وصول ${(report.collectionRate * 100).round()}٪',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      _MixBar(labor: report.labor, parts: report.parts, sales: report.sales),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('روند فروش', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 14),
                      if (report.trend.every((item) => item.amount == 0))
                        const Text('در این بازه فروشی ثبت نشده.', style: TextStyle(color: AppColors.muted))
                      else
                        _TrendChart(points: report.trend),
                    ],
                  ),
                ),
                if (report.insights.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('جمع‌بندی', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 10),
                        ...report.insights.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•  ', style: TextStyle(color: AppColors.copper, fontWeight: FontWeight.w800)),
                                Expanded(child: Text(line, style: const TextStyle(height: 1.55, fontSize: 13))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _RankCard(title: 'پرفروش‌ترین کارها', empty: 'کاری در این بازه نیست.', items: report.topJobs),
                const SizedBox(height: 12),
                _RankCard(title: 'قطعات پرمصرف', empty: 'قطعه‌ای ثبت نشده.', items: report.topParts, countLabel: 'عدد'),
                const SizedBox(height: 12),
                _RankCard(title: 'مشتریان برتر', empty: 'مشتری در این بازه نیست.', items: report.topCustomers),
                const SizedBox(height: 12),
                healthAsync.maybeWhen(
                  data: (health) => _HealthCard(health: health),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SalesHero extends StatelessWidget {
  const _SalesHero({required this.report});

  final PeriodReport report;

  @override
  Widget build(BuildContext context) {
    final up = report.salesDelta >= 0;
    final hasCompare = report.period != ReportPeriod.all;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('فروش بازه', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            MoneyFormat.toman(report.sales),
            style: const TextStyle(color: AppColors.copper, fontWeight: FontWeight.w800, fontSize: 26),
          ),
          if (hasCompare) ...[
            const SizedBox(height: 8),
            Text(
              report.previousSales == 0 && report.sales == 0
                  ? 'بازه قبل هم فروشی نبود'
                  : '${up ? '▲' : '▼'}  ${report.salesDelta.abs()}٪ نسبت به بازه قبل  ·  ${MoneyFormat.compact(report.previousSales)}',
              style: TextStyle(
                color: report.previousSales == 0 && report.sales == 0
                    ? AppColors.muted
                    : (up ? AppColors.teal : AppColors.danger),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}

class _MixBar extends StatelessWidget {
  const _MixBar({required this.labor, required this.parts, required this.sales});

  final int labor;
  final int parts;
  final int sales;

  @override
  Widget build(BuildContext context) {
    final total = sales == 0 ? 1 : sales;
    final laborRatio = (labor / total).clamp(0.0, 1.0);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                if (labor > 0) Expanded(flex: (laborRatio * 1000).round().clamp(1, 1000), child: Container(color: AppColors.teal)),
                if (parts > 0) Expanded(flex: ((1 - laborRatio) * 1000).round().clamp(1, 1000), child: Container(color: AppColors.copper)),
                if (labor == 0 && parts == 0) const Expanded(child: ColoredBox(color: AppColors.voidBg)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _legend('اجرت', labor, AppColors.teal),
        const SizedBox(height: 8),
        _legend('قطعه', parts, AppColors.copper),
      ],
    );
  }

  Widget _legend(String label, int value, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(MoneyFormat.toman(value), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final max = points.fold<int>(0, (sum, item) => item.amount > sum ? item.amount : sum);
    final dense = points.length > 10;
    return Column(
      children: [
        SizedBox(
          height: 148,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in points) ...[
                Expanded(
                  child: Tooltip(
                    message: '${point.label}\n${MoneyFormat.toman(point.amount)}',
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: max == 0 ? 0.04 : (point.amount / max).clamp(0.04, 1.0),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: point.amount == 0 ? AppColors.line : AppColors.copper,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < points.length; i++)
              Expanded(
                child: Text(
                  dense && i != 0 && i != points.length - 1 && i != points.length ~/ 2 ? '' : points[i].label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.title,
    required this.empty,
    required this.items,
    this.countLabel = 'کار',
  });

  final String title;
  final String empty;
  final List<RankedLine> items;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(empty, style: const TextStyle(color: AppColors.muted))
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              final max = items.first.amount == 0 ? 1 : items.first.amount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text('${index + 1}', style: const TextStyle(color: AppColors.copper, fontWeight: FontWeight.w800)),
                        ),
                        Expanded(
                          child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Text(MoneyFormat.compact(item.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    if (item.count > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 22, top: 2),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('${item.count} $countLabel', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                        ),
                      ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: item.amount / max,
                        minHeight: 6,
                        color: AppColors.copper,
                        backgroundColor: AppColors.voidBg,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.health});

  final WorkshopReport health;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('وضعیت فعلی کارگاه', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('بدون فیلتر بازه — تصویر لحظه‌ای', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 12),
          _row('پرونده خودرو', '${health.vehicleCount}'),
          _row('کار باز (تسویه نشده)', '${health.openJobs}'),
          _row('نوبت‌های فعال', '${health.openAppointments}'),
          _row('قطعات کم‌موجود', '${health.lowParts}'),
          _row('بدهی کل', MoneyFormat.toman(health.unpaidTotal)),
          _row('سرویس سررسید', '${health.dueServiceCount}'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
