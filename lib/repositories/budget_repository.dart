import 'package:sqflite/sqflite.dart';
import 'package:spendly/database/database_helper.dart';
import 'package:spendly/models/budget.dart';

class BudgetRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<Budget>> getBudgetsByMonth(String month) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budget',
      where: 'month = ?',
      whereArgs: [month],
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  Future<void> insertOrUpdateBudget(Budget budget) async {
    final db = await _databaseHelper.database;
    
    // Check if budget for this category and month exists
    final List<Map<String, dynamic>> existing = await db.query(
      'budget',
      where: 'categoryId = ? AND month = ?',
      whereArgs: [budget.categoryId, budget.month],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'budget',
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('budget', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> deleteBudget(String id) async {
    final db = await _databaseHelper.database;
    await db.delete('budget', where: 'id = ?', whereArgs: [id]);
  }
}
