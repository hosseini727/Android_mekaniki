import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/customer.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String _query = '';

  String _digitsOnly(String value) {
    const map = {
      '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
      '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final mapped = map[char] ?? char;
      if (RegExp(r'[0-9]').hasMatch(mapped)) {
        buffer.write(mapped);
      }
    }
    return buffer.toString();
  }

  bool _matches(Customer customer, List<Vehicle> vehicles, String needle) {
    if (needle.isEmpty) {
      return true;
    }
    final q = needle.trim();
    final digits = _digitsOnly(q);

    if (customer.name.contains(q)) {
      return true;
    }
    if (customer.phone.contains(q)) {
      return true;
    }
    if (digits.isNotEmpty && _digitsOnly(customer.phone).contains(digits)) {
      return true;
    }

    final cars = vehicles.where((car) => car.ownerPhone == customer.phone);
    for (final car in cars) {
      if (car.ownerName.contains(q)) {
        return true;
      }
      if (car.plate.display.contains(q)) {
        return true;
      }
      if (car.plateKey.contains(q)) {
        return true;
      }
      final plateDigits = _digitsOnly('${car.plate.display}${car.plateKey}');
      if (digits.isNotEmpty && plateDigits.contains(digits)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final asyncCustomers = ref.watch(customersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('مشتریان')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        backgroundColor: AppColors.copper,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('مشتری جدید', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: asyncCustomers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('خطا در بارگذاری مشتریان')),
        data: (bundle) {
          if (bundle.customers.isEmpty) {
            return const AppEmptyState(
              icon: Icons.groups_rounded,
              title: 'مشتری ثبت نشده',
              body: 'با ثبت خودرو، مالک هم اینجا می‌آید.',
            );
          }

          final needle = _query.trim();
          final visible = bundle.customers
              .where((customer) => _matches(customer, bundle.vehicles, needle))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: visible.length + 1,
            separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 12 : 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'جستجو: موبایل، پلاک، نام خانوادگی...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    if (needle.isNotEmpty && visible.isEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'مشتری با این مشخصات پیدا نشد.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ],
                );
              }

              final customer = visible[index - 1];
              final cars = bundle.vehicles.where((car) => car.ownerPhone == customer.phone).toList();
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(customer.phone, style: const TextStyle(color: AppColors.muted)),
                    if ((bundle.debtByPhone[customer.phone] ?? 0) > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'بدهی ${MoneyFormat.toman(bundle.debtByPhone[customer.phone]!)}',
                        style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                    if (customer.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(customer.note, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cars
                          .map(
                            (car) => ActionChip(
                              label: Text(car.plate.display),
                              onPressed: () => context.push(AppRoutes.vehicleHistoryPath(car.id)),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse('tel:${customer.phone}')),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text('تماس'),
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

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final note = TextEditingController();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('مشتری جدید', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 14),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'نام')),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                decoration: const InputDecoration(labelText: 'موبایل'),
              ),
              const SizedBox(height: 10),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'یادداشت')),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
            ],
          ),
        );
      },
    );
    if (saved == true && name.text.trim().isNotEmpty && phone.text.trim().length >= 11) {
      await ref.read(customerRepositoryProvider).upsert(
            CustomerDraft(name: name.text.trim(), phone: phone.text.trim(), note: note.text.trim()),
          );
      ref.invalidate(customersProvider);
    }
    name.dispose();
    phone.dispose();
    note.dispose();
  }
}

class CustomerBundle {
  const CustomerBundle({
    required this.customers,
    required this.vehicles,
    this.debtByPhone = const {},
  });

  final List<Customer> customers;
  final List<Vehicle> vehicles;
  final Map<String, int> debtByPhone;
}
