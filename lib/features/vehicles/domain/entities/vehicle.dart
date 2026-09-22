class IranPlate {
  const IranPlate({
    required this.two,
    required this.letter,
    required this.three,
    required this.region,
  });

  final String two;
  final String letter;
  final String three;
  final String region;

  static const letters = [
    'ب',
    'ج',
    'د',
    'س',
    'ش',
    'ص',
    'ط',
    'ق',
    'ل',
    'م',
    'ن',
    'و',
    'ه',
    'ی',
    'ت',
    'ع',
    'ا',
    'پ',
    'ث',
    'ز',
    'ژ',
    'ف',
    'ک',
    'گ',
  ];

  bool get isComplete =>
      two.length == 2 && letter.isNotEmpty && three.length == 3 && region.length == 2;

  String get key => '$two$letter$three$region';

  String get display => '$two $letter $three  ایران  $region';

  factory IranPlate.empty() =>
      const IranPlate(two: '', letter: 'ب', three: '', region: '');

  factory IranPlate.fromKey(String key) {
    if (key.length < 8) {
      return IranPlate.empty();
    }
    return IranPlate(
      two: key.substring(0, 2),
      letter: key.substring(2, 3),
      three: key.substring(3, 6),
      region: key.substring(6, 8),
    );
  }
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.plateKey,
    required this.ownerName,
    required this.ownerPhone,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.mileage,
    this.platePhotoPath,
    this.vin = '',
    this.nextServiceKm = 0,
  });

  final int id;
  final String plateKey;
  final String ownerName;
  final String ownerPhone;
  final String make;
  final String model;
  final String year;
  final String color;
  final int mileage;
  final String? platePhotoPath;
  final String vin;
  final int nextServiceKm;

  IranPlate get plate => IranPlate.fromKey(plateKey);

  String get title {
    final text = '$make $model'.trim();
    return text.isEmpty ? plate.display : text;
  }

  /// برای لیست‌ها — پلاک دوبار تکرار نشود
  String get listLabel {
    final details = '$make $model'.trim();
    if (details.isNotEmpty) {
      return '$details  ·  ${plate.display}';
    }
    if (ownerName.isNotEmpty) {
      return '$ownerName  ·  ${plate.display}';
    }
    return plate.display;
  }

  bool get isDueForService => nextServiceKm > 0 && mileage >= nextServiceKm;
}
