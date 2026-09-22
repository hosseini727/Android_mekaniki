import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../domain/entities/vehicle.dart';
import '../../domain/plate_parser.dart';
import 'ocr_backend.dart';

class PlateOcrResult {
  const PlateOcrResult({this.plate, this.rawText = ''});

  final IranPlate? plate;
  final String rawText;
}

class PlateOcrService {
  Future<PlateOcrResult> readBytes(Uint8List bytes) async {
    final prepared = _prepare(bytes);
    final raw = await recognizePlateText(prepared);
    return PlateOcrResult(
      plate: PlateParser.fromOcr(raw),
      rawText: raw.trim(),
    );
  }

  Uint8List _prepare(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return bytes;
    }
    var work = decoded;
    if (work.width < 1000) {
      work = img.copyResize(work, width: 1400);
    }
    work = img.grayscale(work);
    work = img.adjustColor(work, contrast: 1.35);
    return Uint8List.fromList(img.encodeJpg(work, quality: 95));
  }
}
