export 'ocr_backend_stub.dart'
    if (dart.library.io) 'ocr_backend_io.dart'
    if (dart.library.js_interop) 'ocr_backend_web.dart';
