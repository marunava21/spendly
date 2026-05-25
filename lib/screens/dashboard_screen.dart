import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:spendly/providers/expense_provider.dart';
import 'package:spendly/widgets/expense_list_item.dart';
import 'package:spendly/screens/expense_search_delegate.dart';
import 'package:spendly/screens/add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ScrollController? _dateScrollController;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ExpenseProvider>().loadExpenses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dateScrollController == null) {
      final screenWidth = MediaQuery.of(context).size.width;
      _dateScrollController = ScrollController(
        initialScrollOffset: 30 * 68.0 - screenWidth / 2 + 34,
      );
    }
    
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = context.read<ExpenseProvider>();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          provider.loadExpenses();
          provider.loadCalendarData(); // Refresh calendar data as well
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('Spendly'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ExpenseSearchDelegate(context.read<ExpenseProvider>()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildFilterDropdown(provider),
              if (provider.currentFilter == DateRangeFilter.daily)
                _buildDateCarousel(provider),
              _buildSummaryCard(provider),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.expenses.isEmpty
                        ? _buildEmptyState()
                        : _buildExpenseList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown(ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          DropdownButton<DateRangeFilter>(
            value: provider.currentFilter,
            onChanged: (DateRangeFilter? newValue) {
              if (newValue != null) {
                provider.setFilter(newValue);
              }
            },
            items: DateRangeFilter.values.map((filter) {
              return DropdownMenuItem(
                value: filter,
                child: Text(
                  filter.toString().split('.').last.replaceAll('this', 'This '),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCarousel(ExpenseProvider provider) {
    final now = DateTime.now();
    return SizedBox(
      height: 70,
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 61,
        itemBuilder: (context, index) {
          final date = now.subtract(Duration(days: 30 - index));
          final isSelected = date.year == provider.selectedDate.year &&
                             date.month == provider.selectedDate.month &&
                             date.day == provider.selectedDate.day;

          return GestureDetector(
            onTap: () => provider.setSelectedDate(date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(ExpenseProvider provider) {
    final dateRangeStr = provider.currentFilter == DateRangeFilter.daily
        ? DateFormat('MMM d, yyyy').format(provider.selectedDate)
        : provider.currentFilter == DateRangeFilter.thisWeek
            ? 'This Week'
            : 'This Month';

    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Total Expenses ($dateRangeStr)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${provider.total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
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
            'No expenses found',
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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddExpenseScreen(expense: expense),
              ),
            );
            provider.loadExpenses();
            provider.loadCalendarData();
          },
        );
      },
    );
  }
}
