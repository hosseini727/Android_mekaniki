class MechanicAccount {
  const MechanicAccount({
    required this.shopName,
    required this.ownerName,
    required this.phone,
  });

  final String shopName;
  final String ownerName;
  final String phone;

  MechanicAccount copyWith({
    String? shopName,
    String? ownerName,
    String? phone,
  }) {
    return MechanicAccount(
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
    );
  }
}
