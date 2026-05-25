import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:spendly/main.dart';
import 'package:sqflite_common/src/factory.dart';

class DummyDatabaseFactory implements SqfliteDatabaseFactory {
  @override
  Future<Database> openDatabase(String path, {OpenDatabaseOptions? options}) async {
    return DummyDatabase();
  }

  @override
  Future<String> getDatabasesPath() async => 'dummy_path';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyDatabase implements Database {
  @override
  bool get isOpen => true;

  @override
  String get path => 'dummy_db';

  @override
  Future<List<Map<String, Object?>>> query(String table, {bool? distinct, List<String>? columns, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) async {
    if (table == 'category') {
      // return default categories so CategoryProvider..loadCategories doesn't crash or hang
      return [
        {'id': 'cat_food', 'name': 'Food', 'colorValue': 0xFFFF9800, 'iconCodePoint': 0xe532},
        {'id': 'cat_transport', 'name': 'Transport', 'colorValue': 0xFF2196F3, 'iconCodePoint': 0xe1d5},
      ];
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App starts test', (WidgetTester tester) async {
    databaseFactory = DummyDatabaseFactory();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const SpendlyApp());

    // Verify that our app has the Spendly title.
    expect(find.text('Spendly Calendar'), findsWidgets);
  });
}
