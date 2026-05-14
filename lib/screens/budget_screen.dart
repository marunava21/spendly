import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/models/budget.dart';
import 'package:spendly/providers/budget_provider.dart';
import 'package:spendly/providers/category_provider.dart';
import 'package:spendly/providers/expense_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final String _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<BudgetProvider>().loadBudgetsForMonth(_currentMonth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: Consumer3<BudgetProvider, CategoryProvider, ExpenseProvider>(
        builder: (context, budgetProvider, categoryProvider, expenseProvider, child) {
          if (budgetProvider.isLoading || categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = categoryProvider.categories;
          final budgets = budgetProvider.budgets;

          Map<String, double> currentMonthExpenses = {};
          for (var e in expenseProvider.expenses) {
            if (DateFormat('yyyy-MM').format(e.date) == _currentMonth) {
               currentMonthExpenses[e.category] = (currentMonthExpenses[e.category] ?? 0.0) + e.amount;
            }
          }

          if (categories.isEmpty) {
            return const Center(child: Text('Add categories first.'));
          }

          return ListView.builder(
            itemCount: categories.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final cat = categories[index];
              // FirstOrNull implementation to avoid StateError
              final budgetList = budgets.where((b) => b.categoryId == cat.id).toList();
              final budget = budgetList.isNotEmpty ? budgetList.first : null;
              
              final spent = currentMonthExpenses[cat.name] ?? 0.0;
              final limit = budget?.amount ?? 0.0;
              final percent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'), color: Color(cat.colorValue)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(cat.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showSetBudgetDialog(context, cat.id, limit),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.grey.shade200,
                        color: percent >= 1.0 ? Colors.red : Theme.of(context).colorScheme.primary,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('\$${spent.toStringAsFixed(2)} spent'),
                          Text(limit > 0 ? '\$${limit.toStringAsFixed(2)} limit' : 'No limit set'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext context, String categoryId, double currentLimit) {
    final controller = TextEditingController(text: currentLimit > 0 ? currentLimit.toString() : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Budget Limit'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              final budget = Budget(
                id: const Uuid().v4(),
                categoryId: categoryId,
                amount: amount,
                month: _currentMonth,
              );
              context.read<BudgetProvider>().saveBudget(budget);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
