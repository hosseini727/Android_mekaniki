import 'package:flutter_test/flutter_test.dart';
import 'package:kargah_yar/features/voice/domain/voice_parser.dart';

void main() {
  test('splits parts and labor from mechanic speech', () {
    final parsed = VoiceParser.fromSpeech('شمع عوض شد چهار میلیون اجرت هشتصد هزار');
    expect(parsed.partsAmount, 4000000);
    expect(parsed.laborAmount, 800000);
    expect(parsed.amount, 4800000);
    expect(parsed.title.contains('شمع'), isTrue);
  });

  test('parses million and implied thousands', () {
    final parsed = VoiceParser.fromSpeech('تعویض روغن یک میلیون و هشتصد هزار');
    expect(parsed.amount, 1800000);
  });

  test('parses latin digits', () {
    final parsed = VoiceParser.fromSpeech('لنت جلو 4200000');
    expect(parsed.amount, 4200000);
  });
}
