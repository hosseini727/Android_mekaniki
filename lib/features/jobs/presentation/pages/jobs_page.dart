import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/pickup_sms_prompt.dart';
import '../../../../core/utils/shamsi_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/repair_job.dart';

class JobsPage extends ConsumerWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJobs = ref.watch(jobsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('دستور کار')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context, ref),
        backgroundColor: AppColors.copper,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('دستور جدید', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: asyncJobs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('خطا در بارگذاری دستور کارها')),
        data: (jobs) {
          if (jobs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.handyman_rounded,
              title: 'دستوری باز نیست',
              body: 'از پذیرش پلاک یا همین صفحه یک دستور کار بساز.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: jobs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _JobTile(job: jobs[index]),
          );
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final vehicles = await ref.read(vehicleRepositoryProvider).all();
    if (!context.mounted || vehicles.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اول یک خودرو از پذیرش پلاک ثبت کن.')),
        );
      }
      return;
    }
    final title = TextEditingController(text: 'تعمیر عمومی');
    var vehicleId = vehicles.first.id;
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
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('دستور کار جدید', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: vehicleId,
                    decoration: const InputDecoration(labelText: 'خودرو'),
                    items: vehicles
                        .map(
                          (car) => DropdownMenuItem(
                            value: car.id,
                            child: Text(car.listLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setModal(() => vehicleId = value ?? vehicleId),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'عنوان کار'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('ثبت دستور'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    if (saved == true) {
      await ref.read(jobRepositoryProvider).save(
            JobDraft(vehicleId: vehicleId, title: title.text.trim()),
          );
      ref.invalidate(jobsProvider);
    }
    title.dispose();
  }
}

class _JobTile extends ConsumerWidget {
  const _JobTile({required this.job});

  final RepairJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ShamsiFormat.monthDay(job.createdAt);
    return AppCard(
      onTap: () => context.push(AppRoutes.vehicleHistoryPath(job.vehicleId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(job.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              StatusChip(label: job.status.labelFa, color: job.status.color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${job.vehicleTitle}  ·  ${job.ownerName}',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text('$date  ·  چاله فعال', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          if (job.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(job.note, style: const TextStyle(height: 1.5, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: JobStatus.values.map((status) {
              final selected = status == job.status;
              return ChoiceChip(
                label: Text(status.labelFa),
                selected: selected,
                onSelected: (value) async {
                  if (!value || status == job.status) {
                    return;
                  }
                  final previous = job.status;
                  await ref.read(jobRepositoryProvider).updateStatus(job.id, status);
                  ref.invalidate(jobsProvider);
                  ref.invalidate(dashboardSnapshotProvider);
                  if (status == JobStatus.done && previous != JobStatus.done && context.mounted) {
                    await _notifyCustomer(context, ref, job);
                  }
                },
              );
            }).toList(),
          ),
          if (job.status == JobStatus.done) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _notifyCustomer(context, ref, job),
              icon: const Icon(Icons.sms_outlined, size: 18),
              label: const Text('پیامک تحویل ماشین'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _notifyCustomer(BuildContext context, WidgetRef ref, RepairJob job) async {
    final vehicle = await ref.read(vehicleRepositoryProvider).findById(job.vehicleId);
    if (!context.mounted) {
      return;
    }
    if (vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('پرونده خودرو پیدا نشد.')),
      );
      return;
    }
    final shop = ref.read(settingsProvider).valueOrNull;
    await PickupSmsPrompt.show(
      context: context,
      vehicle: vehicle,
      jobTitle: job.title,
      shop: shop,
    );
  }
}
