class Budget {
  final String id;
  final String categoryId;
  final double amount;
  final String month; // Format: yyyy-MM

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'month': month,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      categoryId: map['categoryId'],
      amount: map['amount'],
      month: map['month'],
    );
  }
}
