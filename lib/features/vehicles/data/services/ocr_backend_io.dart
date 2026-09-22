import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';

Future<String> recognizePlateText(Uint8List bytes) async {
  final temp = File('${Directory.systemTemp.path}/kargah_plate_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await temp.writeAsBytes(bytes, flush: true);
  try {
    final chunks = <String>[];
    if (Platform.isAndroid || Platform.isIOS) {
      final mlkit = await _readMlKit(temp);
      if (mlkit.isNotEmpty) {
        chunks.add(mlkit);
      }
    }
    if (Platform.isAndroid || Platform.isIOS) {
      final tess = await _readTesseract(temp.path);
      if (tess.isNotEmpty) {
        chunks.add(tess);
      }
    }
    return chunks.join('\n');
  } finally {
    if (await temp.exists()) {
      await temp.delete();
    }
  }
}

Future<String> _readMlKit(File file) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFile(file));
    final blobs = <String>[
      result.text,
      ...result.blocks.map((block) => block.text),
    ];
    return blobs.where((item) => item.trim().isNotEmpty).join('\n');
  } catch (_) {
    return '';
  } finally {
    await recognizer.close();
  }
}

Future<String> _readTesseract(String path) async {
  try {
    return await TesseractOcr.extractText(
      path,
      config: const OCRConfig(
        language: 'fas',
        engine: OCREngine.tesseract,
        options: {
          TesseractConfig.pageSegMode: PageSegmentationMode.sparseTextOsd,
        },
      ),
    );
  } catch (_) {
    return '';
  }
}
