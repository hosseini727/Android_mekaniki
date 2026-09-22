import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/shamsi_format.dart';
import '../../../../core/utils/shamsi_picker.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/appointment.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(scheduleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('نوبت و چاله')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        backgroundColor: AppColors.copper,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.event_available_rounded),
        label: const Text('نوبت جدید', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('خطا در بارگذاری نوبت‌ها')),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'نوبتی نیست',
              body: 'ظرفیت چاله‌ها را از اینجا پر کن.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        StatusChip(label: item.status.labelFa, color: item.status.color),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item.plateText, style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 6),
                    Text(
                      '${ShamsiFormat.withTime(item.scheduledAt)}  ·  چاله ${item.bay}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(item.note, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: AppointmentStatus.values.map((status) {
                        return ChoiceChip(
                          label: Text(status.labelFa),
                          selected: status == item.status,
                          onSelected: (_) async {
                            await ref.read(scheduleRepositoryProvider).updateStatus(item.id, status);
                            ref.invalidate(scheduleProvider);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final plate = TextEditingController();
    final note = TextEditingController();
    final bay = TextEditingController(text: '1');
    var when = DateTime.now().add(const Duration(hours: 2));
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('نوبت جدید', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 14),
                    TextField(controller: name, decoration: const InputDecoration(labelText: 'نام مشتری')),
                    const SizedBox(height: 10),
                    TextField(controller: plate, decoration: const InputDecoration(labelText: 'پلاک')),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bay,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'شماره چاله'),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ShamsiFormat.withTime(when)),
                      trailing: const Icon(Icons.schedule_rounded),
                      onTap: () async {
                        final date = await ShamsiPicker.date(
                          context,
                          initialDate: when,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (date == null || !context.mounted) {
                          return;
                        }
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(when),
                        );
                        if (time == null) {
                          return;
                        }
                        setModal(() {
                          when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      },
                    ),
                    TextField(controller: note, decoration: const InputDecoration(labelText: 'توضیح')),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ثبت نوبت')),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      await ref.read(scheduleRepositoryProvider).save(
            AppointmentDraft(
              customerName: name.text.trim(),
              plateText: plate.text.trim(),
              scheduledAt: when,
              bay: int.tryParse(bay.text) ?? 1,
              note: note.text.trim(),
            ),
          );
      ref.invalidate(scheduleProvider);
    }
    name.dispose();
    plate.dispose();
    note.dispose();
    bay.dispose();
  }
}
