import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/toman_input_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/part_item.dart';

class PartsPage extends ConsumerWidget {
  const PartsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncParts = ref.watch(partsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('قطعات و انبار')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        backgroundColor: AppColors.copper,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('قطعه جدید', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: asyncParts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('خطا در بارگذاری انبار')),
        data: (parts) {
          if (parts.isEmpty) {
            return const AppEmptyState(
              icon: Icons.inventory_2_rounded,
              title: 'انبار خالی است',
              body: 'قطعات پرمصرف کارگاه را اینجا ثبت کن.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: parts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final part = parts[index];
              return AppCard(
                onTap: () => _edit(context, ref, part),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(part.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            '${part.sku}  ·  خرید ${MoneyFormat.compact(part.buyPrice)}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'فروش ${MoneyFormat.toman(part.sellPrice)}',
                            style: const TextStyle(color: AppColors.copper, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        StatusChip(
                          label: part.isLow ? 'کم‌موجود' : '${part.stock} عدد',
                          color: part.isLow ? AppColors.danger : AppColors.teal,
                        ),
                      ],
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

  Future<void> _edit(BuildContext context, WidgetRef ref, PartItem? part) async {
    final name = TextEditingController(text: part?.name ?? '');
    final sku = TextEditingController(text: part?.sku ?? '');
    final stock = TextEditingController(text: part == null ? '' : '${part.stock}');
    final buy = TextEditingController(text: part == null ? '' : TomanInputFormatter.formatInt(part.buyPrice));
    final sell = TextEditingController(text: part == null ? '' : TomanInputFormatter.formatInt(part.sellPrice));
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(part == null ? 'قطعه جدید' : 'ویرایش قطعه', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 14),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'نام قطعه')),
                const SizedBox(height: 10),
                TextField(controller: sku, decoration: const InputDecoration(labelText: 'کد')),
                const SizedBox(height: 10),
                TextField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'موجودی'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: buy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [TomanInputFormatter()],
                  decoration: const InputDecoration(labelText: 'قیمت خرید', suffixText: 'تومان'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sell,
                  keyboardType: TextInputType.number,
                  inputFormatters: [TomanInputFormatter()],
                  decoration: const InputDecoration(labelText: 'قیمت فروش', suffixText: 'تومان'),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
              ],
            ),
          ),
        );
      },
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      await ref.read(partRepositoryProvider).save(
            PartDraft(
              name: name.text.trim(),
              sku: sku.text.trim(),
              stock: int.tryParse(stock.text) ?? 0,
              buyPrice: TomanInputFormatter.parse(buy.text),
              sellPrice: TomanInputFormatter.parse(sell.text),
            ),
            id: part?.id,
          );
      ref.invalidate(partsProvider);
    }
    name.dispose();
    sku.dispose();
    stock.dispose();
    buy.dispose();
    sell.dispose();
  }
}
