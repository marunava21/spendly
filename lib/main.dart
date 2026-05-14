import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:spendly/providers/expense_provider.dart';
import 'package:spendly/providers/category_provider.dart';
import 'package:spendly/providers/budget_provider.dart';
import 'package:spendly/screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpendlyApp());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..loadCategories()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
      ],
      child: MaterialApp(
        title: 'Spendly',
        debugShowCheckedModeBanner: false,
        scrollBehavior: MyCustomScrollBehavior(),
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const MainScreen(),
      ),
    );
  }
}
