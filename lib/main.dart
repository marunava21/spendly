import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendly/providers/expense_provider.dart';
import 'package:spendly/screens/dashboard_screen.dart';

void main() {
  runApp(const SpendlyApp());
}

class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider(),
      child: MaterialApp(
        title: 'Spendly',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const DashboardScreen(),
      ),
    );
  }
}
