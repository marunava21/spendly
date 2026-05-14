import 'package:flutter/foundation.dart';
import 'package:spendly/models/category.dart';
import 'package:spendly/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();
  List<ExpenseCategory> _categories = [];
  bool _isLoading = false;

  List<ExpenseCategory> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    
    _categories = await _repository.getCategories();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(ExpenseCategory category) async {
    await _repository.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    await _repository.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    await loadCategories();
  }
}
