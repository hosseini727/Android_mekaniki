import 'package:flutter_test/flutter_test.dart';
import 'package:kargah_yar/features/auth/data/services/license_code_codec.dart';

void main() {
  test('manual code from the desktop issuer is accepted for the same device', () {
    const machineId = 'AB12-CD34-EF56-7890';
    const code = 'ARR-ZM7H-GZS8-ADHA-HRPX-CSK8-QVEG-XA';

    expect(LicenseCodeCodec.tryValidate(code, machineId), isNull);
    expect(LicenseCodeCodec.daysOf(code), 30);
    expect(LicenseCodeCodec.tryValidate(code, 'FFFF-FFFF-FFFF-FFFF'), isNotNull);
  });
}
