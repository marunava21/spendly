import 'package:flutter/material.dart';
import 'package:spendly/screens/calendar_main_screen.dart';
import 'package:spendly/screens/analytics_screen.dart';
import 'package:spendly/screens/add_expense_screen.dart';
import 'package:provider/provider.dart';
import 'package:spendly/providers/expense_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [CalendarMainScreen(), AnalyticsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = context.read<ExpenseProvider>();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          provider.loadExpenses();
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.pie_chart),
          //   label: 'Analytics',
          // ),
        ],
      ),
    );
  }
}
