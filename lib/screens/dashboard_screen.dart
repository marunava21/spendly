import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

import 'package:spendly/providers/expense_provider.dart';
import 'package:spendly/screens/add_expense_screen.dart';
import 'package:spendly/widgets/expense_list_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) {
        context.read<ExpenseProvider>().loadTodayExpense();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spendly'),
        centerTitle:true,
        elevation: 0,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildTotalCard(context, provider.todayTotal),
              const SizedBox(height: 8),
              _buildDateheader(),
              const SizedBox(height: 8),
              Expanded(child: provider.expenses.isEmpty ? _buildEmptyState() : _buildExpenseList(provider),
                ),
            ],
          );
        },
        ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final provider = context.read<ExpenseProvider>();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddExpenseScreen(),
            ),
          );

          provider.loadTodayExpense();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, double total) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Today\'s Expenses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateheader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            DateFormat('MMM d, yyyy').format(DateTime.now()),
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No expenses today',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(ExpenseProvider provider) {
    return ListView.builder(
      itemCount: provider.expenses.length,
      itemBuilder: (context, index) {
        final expense = provider.expenses[index];
        return ExpenseListItem(
          expense: expense,
          onDelete: () => provider.deleteExpense(expense.id),
        );
      },
    );
  }
}
