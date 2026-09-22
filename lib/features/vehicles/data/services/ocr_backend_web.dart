import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('kargahYarRecognizePlate')
external JSPromise<JSString> _kargahYarRecognizePlate(JSString dataUrl);

Future<String> recognizePlateText(Uint8List bytes) async {
  final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
  final text = await _kargahYarRecognizePlate(dataUrl.toJS).toDart;
  return text.toDart.trim();
}
