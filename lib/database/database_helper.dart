import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'spendly.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expense (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');
    
    await _createV2Tables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
    }
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE category (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        colorValue INTEGER NOT NULL,
        iconCodePoint INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budget (
        id TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES category (id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    final defaultCategories = [
      {'id': 'cat_food', 'name': 'Food', 'colorValue': 0xFFFF9800, 'iconCodePoint': 0xe532}, // Icons.restaurant
      {'id': 'cat_transport', 'name': 'Transport', 'colorValue': 0xFF2196F3, 'iconCodePoint': 0xe1d5}, // Icons.directions_car
      {'id': 'cat_entertainment', 'name': 'Entertainment', 'colorValue': 0xFF9C27B0, 'iconCodePoint': 0xe40a}, // Icons.movie
      {'id': 'cat_shopping', 'name': 'Shopping', 'colorValue': 0xFFE91E63, 'iconCodePoint': 0xe5fc}, // Icons.shopping_bag
      {'id': 'cat_bills', 'name': 'Bills', 'colorValue': 0xFFF44336, 'iconCodePoint': 0xe52a}, // Icons.receipt
      {'id': 'cat_other', 'name': 'Other', 'colorValue': 0xFF009688, 'iconCodePoint': 0xe13c}, // Icons.category
    ];

    for (var cat in defaultCategories) {
      await db.insert('category', cat);
    }
  }
}
