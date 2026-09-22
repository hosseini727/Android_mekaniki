import 'package:flutter_test/flutter_test.dart';
import 'package:kargah_yar/features/vehicles/domain/plate_parser.dart';

void main() {
  test('parses an Iranian plate from OCR text', () {
    final plate = PlateParser.fromOcr('12 ب 345 22');
    expect(plate, isNotNull);
    expect(plate!.two, '12');
    expect(plate.letter, 'ب');
    expect(plate.three, '345');
    expect(plate.region, '22');
    expect(plate.key, '12ب34522');
  });

  test('parses compact OCR digits around the letter', () {
    final plate = PlateParser.fromOcr('IRAN12ب34522');
    expect(plate?.key, '12ب34522');
  });

  test('parses khaki military plate with sheen', () {
    final plate = PlateParser.fromOcr('۱۲ ش ۳۶۵ ایران ۱۱');
    expect(plate?.key, '12ش36511');
    expect(plate?.letter, 'ش');
  });

  test('parses military plate from latin SH alias', () {
    final plate = PlateParser.fromOcr('I.R. IRAN 12 SH 365 11');
    expect(plate?.key, '12ش36511');
  });

  test('fills digits when letter is missing', () {
    final plate = PlateParser.fromOcr('12 365 11');
    expect(plate?.two, '12');
    expect(plate?.three, '365');
    expect(plate?.region, '11');
  });

  test('parses standard white plate with dal', () {
    final plate = PlateParser.fromOcr('۱۲ د ۲۳۶ ایران ۴۶');
    expect(plate?.key, '12د23646');
    expect(plate?.letter, 'د');
  });

  test('parses latin D stand-in for dal', () {
    final plate = PlateParser.fromOcr('I.R. IRAN 12 D 236 46');
    expect(plate?.key, '12د23646');
  });
}
