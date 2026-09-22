import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kargah_yar/app/di/providers.dart';
import 'package:kargah_yar/app/router/app_routes.dart';
import 'package:kargah_yar/core/theme/app_colors.dart';
import 'package:kargah_yar/core/widgets/app_primary_button.dart';
import 'package:kargah_yar/features/vehicles/domain/entities/vehicle.dart';
import 'package:kargah_yar/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:kargah_yar/features/vehicles/presentation/widgets/iran_plate_field.dart';

class VehicleRegisterPage extends ConsumerStatefulWidget {
  const VehicleRegisterPage({super.key, required this.plateKey});

  final String plateKey;

  @override
  ConsumerState<VehicleRegisterPage> createState() => _VehicleRegisterPageState();
}

class _VehicleRegisterPageState extends ConsumerState<VehicleRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _model = TextEditingController();
  final _color = TextEditingController(text: 'سفید');
  final _nextService = TextEditingController();
  late IranPlate _plate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _plate = IranPlate.fromKey(widget.plateKey);
  }

  @override
  void dispose() {
    _owner.dispose();
    _phone.dispose();
    _model.dispose();
    _color.dispose();
    _nextService.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || !_plate.isComplete) {
      return;
    }
    setState(() => _saving = true);
    try {
      final vehicle = await ref.read(vehicleRepositoryProvider).save(
            VehicleDraft(
              plateKey: _plate.key,
              ownerName: _owner.text.trim(),
              ownerPhone: _phone.text.trim(),
              make: '',
              model: _model.text.trim(),
              year: '',
              color: _color.text.trim(),
              mileage: 0,
              vin: '',
              nextServiceKm: int.tryParse(_nextService.text.trim()) ?? 0,
            ),
          );
      ref.invalidate(vehiclesProvider);
      ref.invalidate(customersProvider);
      if (!mounted) {
        return;
      }
      context.pushReplacement(AppRoutes.vehicleHistoryPath(vehicle.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ثبت خودرو انجام نشد. دوباره تلاش کن.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ثبت خودرو جدید')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const Text(
              'موبایل مالک اجباری است. بقیه مشخصات اختیاری‌اند.',
              style: TextStyle(color: AppColors.muted, height: 1.7),
            ),
            const SizedBox(height: 16),
            IranPlateField(
              value: _plate,
              onChanged: (value) => setState(() => _plate = value),
            ),
            const SizedBox(height: 18),
            _field(_owner, 'نام مالک', requiredField: false),
            _field(
              _phone,
              'موبایل مالک',
              keyboard: TextInputType.phone,
              digits: 11,
              requiredField: true,
              requiredHint: true,
            ),
            _field(_model, 'مدل', requiredField: false),
            _field(_color, 'رنگ', requiredField: false),
            _field(_nextService, 'سرویس بعدی (کیلومتر)', keyboard: TextInputType.number, requiredField: false),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'ثبت و باز کردن پرونده',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboard,
    int? digits,
    bool requiredField = false,
    bool requiredHint = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: [
          if (digits != null) FilteringTextInputFormatter.digitsOnly,
          if (digits != null) LengthLimitingTextInputFormatter(digits),
          if (keyboard == TextInputType.number && digits == null) FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: requiredHint ? '$label *' : label,
          hintText: hint,
          helperText: requiredHint ? 'اجباری — ۱۱ رقم' : null,
          helperStyle: requiredHint
              ? const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)
              : null,
        ),
        validator: (value) {
          if (!requiredField) {
            return null;
          }
          if (value == null || value.trim().isEmpty) {
            return '$label را وارد کنید.';
          }
          if (digits != null && value.trim().length < digits) {
            return '$label را کامل وارد کنید.';
          }
          return null;
        },
      ),
    );
  }
}
