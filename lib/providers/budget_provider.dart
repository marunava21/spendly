import 'package:flutter/foundation.dart';
import 'package:spendly/models/budget.dart';
import 'package:spendly/repositories/budget_repository.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _repository = BudgetRepository();
  List<Budget> _budgets = [];
  bool _isLoading = false;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;

  Future<void> loadBudgetsForMonth(String month) async {
    _isLoading = true;
    notifyListeners();
    
    _budgets = await _repository.getBudgetsByMonth(month);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveBudget(Budget budget) async {
    await _repository.insertOrUpdateBudget(budget);
    await loadBudgetsForMonth(budget.month);
  }

  Future<void> deleteBudget(String id, String currentMonth) async {
    await _repository.deleteBudget(id);
    await loadBudgetsForMonth(currentMonth);
  }
}
