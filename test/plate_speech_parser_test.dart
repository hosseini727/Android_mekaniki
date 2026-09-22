import 'package:flutter_test/flutter_test.dart';
import 'package:kargah_yar/features/vehicles/domain/plate_speech_parser.dart';

void main() {
  test('parses spoken compound plate numbers', () {
    final plate = PlateSpeechParser.fromSpeech('دوازده ب سیصد و چهل و پنج بیست و دو');
    expect(plate?.key, '12ب34522');
  });

  test('parses spoken letter names', () {
    final plate = PlateSpeechParser.fromSpeech('پلاک دوازده دال دویست و سی و شش ایران چهل و شش');
    expect(plate?.key, '12د23646');
    expect(plate?.letter, 'د');
  });

  test('parses digit-by-digit speech', () {
    final plate = PlateSpeechParser.fromSpeech('یک دو شین سه شش پنج یک یک');
    expect(plate?.key, '12ش36511');
  });

  test('parses already numeric speech', () {
    final plate = PlateSpeechParser.fromSpeech('۱۲ ب ۳۴۵ ۲۲');
    expect(plate?.key, '12ب34522');
  });

  test('parses به as letter ب', () {
    final plate = PlateSpeechParser.fromSpeech('دوازده به سیصد چهل پنج بیست دو');
    expect(plate?.key, '12ب34522');
  });

  test('parses latin letter from speech engines', () {
    final plate = PlateSpeechParser.fromSpeech('12 b 345 22');
    expect(plate?.key, '12ب34522');
  });
}
