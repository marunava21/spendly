class ExpenseCategory {
  final String id;
  final String name;
  final int colorValue;
  final int iconCodePoint;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'],
      name: map['name'],
      colorValue: map['colorValue'],
      iconCodePoint: map['iconCodePoint'],
    );
  }
}
