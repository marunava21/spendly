import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:spendly/providers/expense_provider.dart';
import 'package:spendly/providers/category_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = context.read<ExpenseProvider>().selectedDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      final amount = double.parse(_amountController.text);
      final note = _noteController.text.trim();

      context.read<ExpenseProvider>().addExpense(
            amount: amount,
            category: _selectedCategory!,
            date: _selectedDate,
            note: note.isEmpty ? null : note,
          );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    final categories = categoryProvider.categories;
                    
                    if (categories.isEmpty && categoryProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Ensure selected category is in the list, otherwise null
                    if (_selectedCategory != null && 
                        !categories.any((c) => c.name == _selectedCategory)) {
                      _selectedCategory = null;
                    }
                    
                    if (_selectedCategory == null && categories.isNotEmpty) {
                      _selectedCategory = categories.first.name;
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category.name,
                          child: Row(
                            children: [
                              Icon(
                                IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                                color: Color(category.colorValue),
                              ),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a category' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Date: ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null && mounted) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Expense',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
