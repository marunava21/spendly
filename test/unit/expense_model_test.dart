import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/models/expense.dart';

void main() {
  group('Expense Model', () {
    final testExpense = Expense(
      id: '1',
      amount: 12.50,
      category: 'Food',
      date: DateTime(2026, 4, 12),
      note: 'Lunch',
    );
    test('toMap produces correct keys and values', () {
      final map = testExpense.toMap();
      expect(map['id'], equals('1'));
      expect(map['amount'], equals(12.5));
      expect(map['category'], equals('Food'));
      expect(map['note'], equals('Lunch'));
    });

    test('fromMap restores the object correctly', () {
      final map = testExpense.toMap();
      final restored = Expense.fromMap(map);
      expect(restored.id, equals('1'));
      expect(restored.amount, equals(12.50));
      expect(restored.category, equals('Food'));
      expect(restored.note, equals('Lunch'));
    });

    test('toMap and fromMap round-trip preserves all fields', () {
      final restored = Expense.fromMap(testExpense.toMap());
      expect(restored.id, equals(testExpense.id));
      expect(restored.amount, equals(testExpense.amount));
      expect(restored.date, equals(testExpense.date));
    });
    test('copyWith updates only specific fields', () {
      final updated = testExpense.copyWith(amount: 99.0);
      expect(updated.amount, equals(99.0));
      expect(updated.category, equals('Food'));
      expect(updated.id, equals('1'));
    });
    test('note is nullable', () {
      final noNote = Expense(
        id: '2',
        amount: 5.0,
        category: 'Transport',
        date: DateTime(2026, 4, 12),
      );
      expect(noNote.note, isNull);
    });
  });
}
