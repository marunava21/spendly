import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository;
  final __uuid = const Uuid();

  List<Expense> _expense = [];
  double _todayTotal = 0.0;
  bool _isLoading = false;

  List<Expense> get expenses => _expense;
  double get todayTotal => _todayTotal;
  bool get isLoading => _isLoading;

  ExpenseProvider({ExpenseRepository? repository})
    : _repository = repository ?? ExpenseRepository();

  Future<void> loadTodayExpense() async {
    _isLoading = true;
    notifyListeners();
    _expense = await _repository.getExpenseByDate(DateTime.now());
    _todayTotal = await _repository.getTodayTotal();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    String? note,
  }) async {
    final expense = Expense(
      id: __uuid.v4(),
      amount: amount,
      category: category,
      date: DateTime.now(),
      note: note,
    );
    await _repository.insertExpense(expense);
    await loadTodayExpense();
  }

  Future<void> deleteExpense(String id) async {
    await _repository.deleteExpense(id);
    await loadTodayExpense();
  }
}
