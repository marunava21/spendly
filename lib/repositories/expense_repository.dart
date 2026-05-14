import 'package:spendly/database/database_helper.dart';
import 'package:spendly/models/expense.dart';
import 'package:sqflite/sql.dart';

class ExpenseRepository {
  final DatabaseHelper _dbHelper;

  ExpenseRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Expense>> getAllExpense() async {
    final db = await _dbHelper.database;
    final maps = await db.query('expense', orderBy: 'date DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> getExpenseByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    ).toIso8601String();
    final maps = await db.query(
      'expense',
      where: 'date between ? and ?',
      whereArgs: [start, end],
      orderBy: 'date Desc',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();
    final maps = await db.query(
      'expense',
      where: 'date between ? and ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date Desc',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> searchExpenses(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expense',
      where: 'note LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date Desc',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await _dbHelper.database;
    await db.insert(
      'expense',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await _dbHelper.database;
    await db.delete('expense', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTodayTotal() async {
    final expenses = await getExpenseByDate(DateTime.now());
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }
}
