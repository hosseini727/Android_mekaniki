class PartItem {
  const PartItem({
    required this.id,
    required this.name,
    required this.stock,
    required this.buyPrice,
    required this.sellPrice,
    this.sku = '',
  });

  final int id;
  final String name;
  final String sku;
  final int stock;
  final int buyPrice;
  final int sellPrice;

  int get margin => sellPrice - buyPrice;
  bool get isLow => stock <= 3;
}

class PartDraft {
  const PartDraft({
    required this.name,
    required this.stock,
    required this.buyPrice,
    required this.sellPrice,
    this.sku = '',
  });

  final String name;
  final String sku;
  final int stock;
  final int buyPrice;
  final int sellPrice;
}
