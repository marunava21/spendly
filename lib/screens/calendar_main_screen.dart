import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:spendly/providers/expense_provider.dart';
import 'package:spendly/screens/dashboard_screen.dart';
import 'package:spendly/screens/category_list_screen.dart';
import 'package:spendly/screens/budget_screen.dart';

class CalendarMainScreen extends StatefulWidget {
  const CalendarMainScreen({super.key});

  @override
  State<CalendarMainScreen> createState() => _CalendarMainScreenState();
}

class _CalendarMainScreenState extends State<CalendarMainScreen> {
  final PageController _pageController = PageController(initialPage: 1200);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<ExpenseProvider>().loadCalendarData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryListScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Budgets'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen()));
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Spendly Calendar'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadCalendarData();
              await provider.loadExpenses();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildCalendarHeader(provider),
                _buildDaysOfWeek(),
                _buildCalendarGrid(provider),
                const SizedBox(height: 32),
                _buildMonthlyTotal(provider),
                const SizedBox(height: 80), // Padding to avoid FAB overlap
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarHeader(ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(provider.viewedMonth),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) => Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: (day == 'Sun' || day == 'Sat') ? Colors.blue.shade800 : Colors.black87,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(ExpenseProvider provider) {
    return SizedBox(
      height: 380, // Fixed height for 6 rows
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          final offset = index - 1200;
          final now = DateTime.now();
          final newMonth = DateTime(now.year, now.month + offset, 1);
          provider.setViewedMonth(newMonth);
        },
        itemBuilder: (context, index) {
          final offset = index - 1200;
          final now = DateTime.now();
          final monthDate = DateTime(now.year, now.month + offset, 1);
          
          return _buildMonthView(context, provider, monthDate);
        },
      ),
    );
  }

  Widget _buildMonthView(BuildContext context, ExpenseProvider provider, DateTime monthDate) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final startingWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final totalCells = 42; 

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < startingWeekday || index >= startingWeekday + daysInMonth) {
          return const SizedBox.shrink(); 
        }
        
        final day = index - startingWeekday + 1;
        final cellDate = DateTime(monthDate.year, monthDate.month, day);
        
        final isSelected = cellDate.year == provider.selectedDate.year &&
                           cellDate.month == provider.selectedDate.month &&
                           cellDate.day == provider.selectedDate.day;
                           
        final totalSpent = provider.calendarDailyTotals[cellDate] ?? 0.0;
        final isWeekend = cellDate.weekday == 6 || cellDate.weekday == 7;

        final transactionTypes = provider.calendarDailyTransactionTypes[cellDate] ?? {};
        bool hasOwe = transactionTypes.contains('owe');
        bool hasOwed = transactionTypes.contains('owed');
        bool hasInvestment = transactionTypes.contains('investment');

        return GestureDetector(
          onTap: () {
            provider.setSelectedDate(cellDate);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          },
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : (totalSpent > 0 ? Colors.teal.shade50 : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected 
                              ? Colors.white 
                              : (isWeekend ? Colors.blue.shade800 : Colors.black87),
                        ),
                      ),
                      if (totalSpent > 0)
                        Text(
                          totalSpent.toInt().toString(), 
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.teal.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (hasOwe || hasOwed || hasInvestment)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasOwed)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        ),
                      if (hasOwe)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      if (hasInvestment)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyTotal(ExpenseProvider provider) {
    return Column(
      children: [
        Text(
          'Total Expense this Month',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${provider.calendarMonthlyTotal.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (provider.monthlyOwe > 0 || provider.monthlyOwed > 0) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (provider.monthlyOwe > 0)
                Column(
                  children: [
                    Text('I Owe', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${provider.monthlyOwe.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              if (provider.monthlyOwed > 0)
                Column(
                  children: [
                    Text('Owed to Me', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${provider.monthlyOwed.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
            ],
          ),
        ],
        if (provider.monthlyInvestment > 0) ...[
          const SizedBox(height: 16),
          Text(
            'Total Investment',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${provider.monthlyInvestment.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ],
    );
  }
}
