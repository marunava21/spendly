import 'package:sqflite/sqflite.dart';
import 'package:spendly/database/database_helper.dart';
import 'package:spendly/models/category.dart';

class CategoryRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<ExpenseCategory>> getCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('category');
    return List.generate(maps.length, (i) => ExpenseCategory.fromMap(maps[i]));
  }

  Future<void> insertCategory(ExpenseCategory category) async {
    final db = await _databaseHelper.database;
    await db.insert('category', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    final db = await _databaseHelper.database;
    await db.update(
      'category',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await _databaseHelper.database;
    await db.delete('category', where: 'id = ?', whereArgs: [id]);
  }
}
