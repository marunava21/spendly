import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/repositories/expense_repository.dart';

enum DateRangeFilter { daily, thisWeek, thisMonth }

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository;
  final __uuid = const Uuid();

  List<Expense> _expense = [];
  double _total = 0.0;
  bool _isLoading = false;
  DateRangeFilter _currentFilter = DateRangeFilter.daily;
  DateTime _selectedDate = DateTime.now();
  DateTime _viewedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  Map<String, double> _categoryTotals = {};
  Map<String, double> _dailyTotals = {};
  Map<DateTime, double> _calendarDailyTotals = {};
  Map<DateTime, Set<String>> _calendarDailyTransactionTypes = {};
  double _calendarMonthlyTotal = 0.0;
  double _monthlyOwe = 0.0;
  double _monthlyOwed = 0.0;
  double _monthlyInvestment = 0.0;

  List<Expense> get expenses => _expense;
  double get total => _total;
  bool get isLoading => _isLoading;
  DateRangeFilter get currentFilter => _currentFilter;
  DateTime get selectedDate => _selectedDate;
  DateTime get viewedMonth => _viewedMonth;
  Map<String, double> get categoryTotals => _categoryTotals;
  Map<String, double> get dailyTotals => _dailyTotals;
  Map<DateTime, double> get calendarDailyTotals => _calendarDailyTotals;
  Map<DateTime, Set<String>> get calendarDailyTransactionTypes => _calendarDailyTransactionTypes;
  double get calendarMonthlyTotal => _calendarMonthlyTotal;
  double get monthlyOwe => _monthlyOwe;
  double get monthlyOwed => _monthlyOwed;
  double get monthlyInvestment => _monthlyInvestment;

  ExpenseProvider({ExpenseRepository? repository})
    : _repository = repository ?? ExpenseRepository();

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_currentFilter) {
      case DateRangeFilter.daily:
        start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
        break;
      case DateRangeFilter.thisWeek:
        start = DateTime(now.year, now.month, now.day - now.weekday + 1);
        break;
      case DateRangeFilter.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
    }

    _expense = await _repository.getExpensesByDateRange(start, end);
    
    // Only normal expenses count towards standard totals
    final normalExpenses = _expense.where((e) => e.transactionType == 'expense').toList();
    _total = normalExpenses.fold(0.0, (sum, e) => sum + e.amount);

    _categoryTotals = {};
    _dailyTotals = {};
    for (var e in normalExpenses) {
      _categoryTotals[e.category] = (_categoryTotals[e.category] ?? 0.0) + e.amount;
      
      // We use 'yyyy-MM-dd' to easily sort them chronologically later if needed
      String dateKey = e.date.toIso8601String().substring(0, 10);
      _dailyTotals[dateKey] = (_dailyTotals[dateKey] ?? 0.0) + e.amount;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFilter(DateRangeFilter filter) {
    _currentFilter = filter;
    loadExpenses();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    if (_currentFilter != DateRangeFilter.daily) {
      _currentFilter = DateRangeFilter.daily;
    }
    loadExpenses();
  }

  void setViewedMonth(DateTime month) {
    _viewedMonth = DateTime(month.year, month.month, 1);
    loadCalendarData();
  }

  Future<void> loadCalendarData() async {
    final start = _viewedMonth;
    final end = DateTime(_viewedMonth.year, _viewedMonth.month + 1, 0, 23, 59, 59);
    final expenses = await _repository.getExpensesByDateRange(start, end);
    
    _calendarDailyTotals = {};
    _calendarDailyTransactionTypes = {};
    _calendarMonthlyTotal = 0.0;
    _monthlyOwe = 0.0;
    _monthlyOwed = 0.0;
    _monthlyInvestment = 0.0;
    
    for (var e in expenses) {
      final dateOnly = DateTime(e.date.year, e.date.month, e.date.day);
      
      _calendarDailyTransactionTypes.putIfAbsent(dateOnly, () => {});
      _calendarDailyTransactionTypes[dateOnly]!.add(e.transactionType);
      
      if (e.transactionType == 'expense') {
        _calendarDailyTotals[dateOnly] = (_calendarDailyTotals[dateOnly] ?? 0.0) + e.amount;
        _calendarMonthlyTotal += e.amount;
      } else if (e.transactionType == 'owed') {
        _monthlyOwed += e.amount;
      } else if (e.transactionType == 'owe') {
        _monthlyOwe += e.amount;
      } else if (e.transactionType == 'investment') {
        _monthlyInvestment += e.amount;
      }
    }
    notifyListeners();
  }

  Future<List<Expense>> searchExpensesReturnList(String query) async {
    return await _repository.searchExpenses(query);
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    DateTime? date,
    String? note,
    String transactionType = 'expense',
    String? personName,
    String? personEmail,
    String? brokerName,
    String? companyName,
  }) async {
    final expense = Expense(
      id: __uuid.v4(),
      amount: amount,
      category: category,
      date: date ?? DateTime.now(),
      note: note,
      transactionType: transactionType,
      personName: personName,
      personEmail: personEmail,
      brokerName: brokerName,
      companyName: companyName,
    );
    await _repository.insertExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _repository.deleteExpense(id);
    await loadExpenses();
  }
}
