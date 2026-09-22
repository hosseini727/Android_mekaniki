class ShopSettings {
  const ShopSettings({
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.address,
  });

  final String shopName;
  final String ownerName;
  final String phone;
  final String address;

  ShopSettings copyWith({
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
  }) {
    return ShopSettings(
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  static const defaults = ShopSettings(
    shopName: '',
    ownerName: '',
    phone: '',
    address: '',
  );
}
