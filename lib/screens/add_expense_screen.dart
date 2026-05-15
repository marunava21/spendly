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
  final _personNameController = TextEditingController();
  final _brokerNameController = TextEditingController();
  final _companyNameController = TextEditingController();

  String _transactionType = 'expense'; // 'expense', 'owe', 'owed', 'investment'
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
    _personNameController.dispose();
    _brokerNameController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      if (_transactionType == 'expense' && _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      final amount = double.parse(_amountController.text);
      final note = _noteController.text.trim();
      final personName = _personNameController.text.trim();
      final brokerName = _brokerNameController.text.trim();
      final companyName = _companyNameController.text.trim();

      String savedCategory = _selectedCategory ?? '';
      if (_transactionType == 'owe' || _transactionType == 'owed') {
        savedCategory = 'IOU';
      } else if (_transactionType == 'investment') {
        savedCategory = 'Investment';
      }

      context.read<ExpenseProvider>().addExpense(
            amount: amount,
            category: savedCategory,
            date: _selectedDate,
            note: note.isEmpty ? null : note,
            transactionType: _transactionType,
            personName: (_transactionType == 'owe' || _transactionType == 'owed') 
                ? (personName.isEmpty ? null : personName) : null,
            brokerName: _transactionType == 'investment' 
                ? (brokerName.isEmpty ? null : brokerName) : null,
            companyName: _transactionType == 'investment' 
                ? (companyName.isEmpty ? null : companyName) : null,
          );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Add Expense';
    if (_transactionType == 'owe' || _transactionType == 'owed') title = 'Add IOU';
    if (_transactionType == 'investment') title = 'Add Investment';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Expense')),
                      ButtonSegment(value: 'investment', label: Text('Invest')),
                      ButtonSegment(value: 'owe', label: Text('I Owe')),
                      ButtonSegment(value: 'owed', label: Text('Owed')),
                    ],
                    selected: {_transactionType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _transactionType = newSelection.first;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
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
                
                if (_transactionType == 'expense')
                  Consumer<CategoryProvider>(
                    builder: (context, categoryProvider, child) {
                      final categories = categoryProvider.categories;
                      
                      if (categories.isEmpty && categoryProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

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
                        validator: (value) => _transactionType == 'expense' && value == null 
                            ? 'Please select a category' 
                            : null,
                      );
                    },
                  )
                else if (_transactionType == 'investment') ...[
                  TextFormField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Company/Asset Name (e.g. AAPL)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (_transactionType == 'investment' && (value == null || value.isEmpty)) {
                        return 'Please enter a company name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _brokerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Broker Name (e.g. Robinhood)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    validator: (value) {
                      if (_transactionType == 'investment' && (value == null || value.isEmpty)) {
                        return 'Please enter a broker name';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _personNameController,
                    decoration: const InputDecoration(
                      labelText: 'Person Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if ((_transactionType == 'owe' || _transactionType == 'owed') && (value == null || value.isEmpty)) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                ],
                  
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
                    'Save Transaction',
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
