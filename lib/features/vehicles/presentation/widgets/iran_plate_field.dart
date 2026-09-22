import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/vehicle.dart';

class IranPlateField extends StatefulWidget {
  const IranPlateField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final IranPlate value;
  final ValueChanged<IranPlate> onChanged;

  @override
  State<IranPlateField> createState() => _IranPlateFieldState();
}

class _IranPlateFieldState extends State<IranPlateField> {
  late final TextEditingController _two;
  late final TextEditingController _three;
  late final TextEditingController _region;

  @override
  void initState() {
    super.initState();
    _two = TextEditingController(text: widget.value.two);
    _three = TextEditingController(text: widget.value.three);
    _region = TextEditingController(text: widget.value.region);
  }

  @override
  void didUpdateWidget(covariant IranPlateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(_two, widget.value.two);
    _sync(_three, widget.value.three);
    _sync(_region, widget.value.region);
  }

  void _sync(TextEditingController controller, String text) {
    if (controller.text != text) {
      controller.text = text;
    }
  }

  @override
  void dispose() {
    _two.dispose();
    _three.dispose();
    _region.dispose();
    super.dispose();
  }

  void _emit({String? two, String? letter, String? three, String? region}) {
    widget.onChanged(
      IranPlate(
        two: two ?? _two.text,
        letter: letter ?? widget.value.letter,
        three: three ?? _three.text,
        region: region ?? _region.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1EA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1D2430), width: 1.4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: _Digits(controller: _two, maxLength: 2, onChanged: (two) => _emit(two: two)),
            ),
            Container(width: 1, color: const Color(0xFF1D2430)),
            SizedBox(
              width: 58,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.value.letter,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  iconEnabledColor: Colors.black87,
                  items: IranPlate.letters
                      .map(
                        (letter) => DropdownMenuItem(
                          value: letter,
                          child: Center(
                            child: Text(
                              letter,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (letter) => _emit(letter: letter),
                ),
              ),
            ),
            Container(width: 1, color: const Color(0xFF1D2430)),
            Expanded(
              child: _Digits(
                controller: _three,
                maxLength: 3,
                onChanged: (three) => _emit(three: three),
              ),
            ),
            Container(
              width: 52,
              color: const Color(0xFF163A73),
              alignment: Alignment.center,
              child: const Text(
                'ایران',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 72,
              color: const Color(0xFF163A73),
              alignment: Alignment.center,
              child: _Digits(
                controller: _region,
                maxLength: 2,
                light: true,
                onChanged: (region) => _emit(region: region),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Digits extends StatelessWidget {
  const _Digits({
    required this.controller,
    required this.maxLength,
    required this.onChanged,
    this.light = false,
  });

  final TextEditingController controller;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      style: TextStyle(
        color: light ? Colors.white : Colors.black,
        fontWeight: FontWeight.w800,
        fontSize: 22,
        letterSpacing: 2,
      ),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: onChanged,
    );
  }
}
