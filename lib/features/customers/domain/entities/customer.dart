class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.note = '',
  });

  final int id;
  final String name;
  final String phone;
  final String note;
}

class CustomerDraft {
  const CustomerDraft({
    required this.name,
    required this.phone,
    this.note = '',
  });

  final String name;
  final String phone;
  final String note;
}
