import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final srcFile = File('assets/images/app_icon_source.png');
  final decoded = img.decodeImage(srcFile.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Failed to decode source icon');
    exit(1);
  }

  // Crop to square center if needed
  final side = decoded.width < decoded.height ? decoded.width : decoded.height;
  final ox = (decoded.width - side) ~/ 2;
  final oy = (decoded.height - side) ~/ 2;
  final square = img.copyCrop(decoded, x: ox, y: oy, width: side, height: side);

  void writePng(String path, int size) {
    final resized = img.copyResize(square, width: size, height: size, interpolation: img.Interpolation.cubic);
    File(path).writeAsBytesSync(img.encodePng(resized));
    stdout.writeln('Wrote $path ($size)');
  }

  // App logo (in-app)
  writePng('assets/images/logo.png', 512);

  // Android mipmaps
  writePng('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48);
  writePng('android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72);
  writePng('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96);
  writePng('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144);
  writePng('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192);

  // Web
  writePng('web/favicon.png', 48);
  writePng('web/icons/Icon-192.png', 192);
  writePng('web/icons/Icon-512.png', 512);
  writePng('web/icons/Icon-maskable-192.png', 192);
  writePng('web/icons/Icon-maskable-512.png', 512);

  stdout.writeln('Done');
}
