class Expense {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final String transactionType; // 'expense', 'owe', 'owed', 'investment'
  final String? personName;
  final String? personEmail;
  final String? brokerName;
  final String? companyName;
  final String currency;
  final double conversionRate;
  final double? originalAmount;
  final String? invoicePath;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.transactionType = 'expense',
    this.personName,
    this.personEmail,
    this.brokerName,
    this.companyName,
    this.currency = 'SGD',
    this.conversionRate = 1.0,
    this.originalAmount,
    this.invoicePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'transactionType': transactionType,
      'personName': personName,
      'personEmail': personEmail,
      'brokerName': brokerName,
      'companyName': companyName,
      'currency': currency,
      'conversionRate': conversionRate,
      'originalAmount': originalAmount,
      'invoicePath': invoicePath,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      transactionType: map['transactionType'] ?? 'expense',
      personName: map['personName'],
      personEmail: map['personEmail'],
      brokerName: map['brokerName'],
      companyName: map['companyName'],
      currency: map['currency'] ?? 'SGD',
      conversionRate: map['conversionRate'] ?? 1.0,
      originalAmount: map['originalAmount'],
      invoicePath: map['invoicePath'],
    );
  }

  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? transactionType,
    String? personName,
    String? personEmail,
    String? brokerName,
    String? companyName,
    String? currency,
    double? conversionRate,
    double? originalAmount,
    String? invoicePath,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      transactionType: transactionType ?? this.transactionType,
      personName: personName ?? this.personName,
      personEmail: personEmail ?? this.personEmail,
      brokerName: brokerName ?? this.brokerName,
      companyName: companyName ?? this.companyName,
      currency: currency ?? this.currency,
      conversionRate: conversionRate ?? this.conversionRate,
      originalAmount: originalAmount ?? this.originalAmount,
      invoicePath: invoicePath ?? this.invoicePath,
    );
  }
}
