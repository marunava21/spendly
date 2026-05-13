import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:spendly/database/database_helper.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/repositories/expense_repository.dart';
import 'package:sqflite/sqflite.dart';

import 'expense_repository_test.mocks.dart';

@GenerateMocks([DatabaseHelper, Database])
void main() {
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDatabase;
  late ExpenseRepository repository;

  final testExpense = Expense(
    id: '1',
    amount: 25.0,
    category: 'Food',
    date: DateTime(2026, 4, 12, 10, 0, 0),
    note: 'Breakfast',
  );

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    repository = ExpenseRepository(dbHelper: mockDbHelper);

    when(mockDbHelper.database).thenAnswer((_) async => mockDatabase);
  });

  group('ExpenseRepository', () {
    test('insertExpense calls db.insert with correct table', () async {
      when(
        mockDatabase.insert(
          any,
          any,
          conflictAlgorithm: anyNamed('conflictAlgorithm'),
        ),
      ).thenAnswer((_) async => 1);
      await repository.insertExpense(testExpense);

      verify(
        mockDatabase.insert(
          'expense',
          testExpense.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      ).called(1);
    });

    test('getAllExpense returns list of expenses', () async {
      when(
        mockDatabase.query('expenses', orderBy: anyNamed('orderBy')),
      ).thenAnswer((_) async => [testExpense.toMap()]);

      final result = await repository.getAllExpense();

      expect(result.length, equals(1));
      expect(result.first.id, equals('1'));
      expect(result.first.amount, equals(25.0));
    });

    test('deleteExpense sums amount correctly', () async {
      when(
        mockDatabase.delete(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => 1);
      await repository.deleteExpense('1');
      verify(
        mockDatabase.delete('expense', where: 'id=?', whereArgs: ['1']),
      ).called(1);
    });

    test('gettodayTotal sums amounts correctly', () async {
      final expense2 = testExpense.copyWith(id: '2', amount: 15.0);
      when(
        mockDatabase.query(
          'expense',
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => [testExpense.toMap(), expense2.toMap()]);

      final total = await repository.getTodayTotal();

      expect(total, equals(40.0));
    });
  });
}
