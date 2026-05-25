import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/providers/expense_provider.dart';
import 'package:spendly/providers/category_provider.dart';
import 'package:spendly/utils/statement_parser.dart';

class ImportReviewScreen extends StatefulWidget {
  final List<ParsedTransaction> transactions;

  const ImportReviewScreen({super.key, required this.transactions});

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ReviewItemState {
  bool isSelected = true;
  DateTime date;
  String note;
  double amount;
  String category;
  String transactionType;

  final TextEditingController noteController;
  final TextEditingController amountController;

  _ReviewItemState({
    required ParsedTransaction tx,
  })  : date = tx.date,
        note = tx.note,
        amount = tx.amount,
        category = tx.category,
        transactionType = tx.transactionType,
        noteController = TextEditingController(text: tx.note),
        amountController = TextEditingController(text: tx.amount.toStringAsFixed(2)) {
    noteController.addListener(() {
      note = noteController.text;
    });
    amountController.addListener(() {
      amount = double.tryParse(amountController.text) ?? 0.0;
    });
  }

  void dispose() {
    noteController.dispose();
    amountController.dispose();
  }
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  List<_ReviewItemState> _items = [];
  String _searchQuery = "";
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _items = widget.transactions.map((tx) => _ReviewItemState(tx: tx)).toList();
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  // Handle transaction date edit
  Future<void> _selectDate(BuildContext context, _ReviewItemState item) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: item.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        item.date = pickedDate;
      });
    }
  }

  // Bulk save and import
  Future<void> _importSelected() async {
    if (_formKey.currentState!.validate()) {
      final selectedItems = _items.where((item) => item.isSelected).toList();
      if (selectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select at least one transaction to import"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isImporting = true);

      try {
        final expenses = selectedItems.map((item) {
          String savedCategory = item.category;
          String? personName;
          String? companyName;
          String? brokerName;

          if (item.transactionType == 'owe' || item.transactionType == 'owed') {
            savedCategory = 'IOU';
            personName = item.note.trim();
          } else if (item.transactionType == 'investment') {
            savedCategory = 'Investment';
            companyName = item.note.trim();
            brokerName = 'Imported';
          }

          return Expense(
            id: _uuid.v4(),
            amount: item.amount,
            category: savedCategory,
            date: item.date,
            note: item.note.isEmpty ? null : item.note,
            transactionType: item.transactionType,
            personName: personName,
            companyName: companyName,
            brokerName: brokerName,
            currency: 'SGD',
            conversionRate: 1.0,
            originalAmount: item.amount,
          );
        }).toList();

        await context.read<ExpenseProvider>().addExpenses(expenses);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Successfully imported ${expenses.length} transactions"),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Pop twice to return to Dashboard/Calendar screen
          Navigator.pop(context); // Pop review
          Navigator.pop(context); // Pop import picker
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to import transactions: $e"),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isImporting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = context.watch<CategoryProvider>();

    final filteredItems = _items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.note.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Summary calculations
    final selectedCount = _items.where((item) => item.isSelected).length;
    final totalAmount = _items
        .where((item) => item.isSelected)
        .fold<double>(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Transactions"),
        actions: [
          TextButton(
            onPressed: () {
              final allSelected = _items.every((item) => item.isSelected);
              setState(() {
                for (var item in _items) {
                  item.isSelected = !allSelected;
                }
              });
            },
            child: Text(
              _items.every((item) => item.isSelected) ? "Deselect All" : "Select All",
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search parsed transactions...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: filteredItems.isEmpty
                  ? const Center(child: Text("No transactions match your search filter"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildTransactionCard(theme, item, categoryProvider);
                      },
                    ),
            ),
          ),
          // Persistent Summary Bottom Bar
          _buildSummaryBottomBar(theme, selectedCount, totalAmount),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    ThemeData theme,
    _ReviewItemState item,
    CategoryProvider categoryProvider,
  ) {
    final categories = categoryProvider.categories;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.isSelected ? theme.colorScheme.primary.withAlpha(128) : Colors.grey.shade300,
          width: item.isSelected ? 2 : 1,
        ),
      ),
      color: item.isSelected ? theme.colorScheme.primaryContainer.withAlpha(20) : null,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Checkbox(
              value: item.isSelected,
              activeColor: theme.colorScheme.primary,
              onChanged: (val) {
                setState(() {
                  item.isSelected = val ?? false;
                });
              },
            ),
            const SizedBox(width: 8),
            // Form fields
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row for Date and Amount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Selector
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(context, item),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            alignment: Alignment.centerLeft,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            DateFormat('MMM d, yyyy').format(item.date),
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Amount Field
                      Expanded(
                        child: TextFormField(
                          controller: item.amountController,
                          decoration: const InputDecoration(
                            labelText: "Amount (SGD)",
                            prefixText: "\$ ",
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (!item.isSelected) return null;
                            if (v == null || v.isEmpty) return "Enter amount";
                            final parsed = double.tryParse(v);
                            if (parsed == null || parsed <= 0) return "Invalid";
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Note Field
                  TextFormField(
                    controller: item.noteController,
                    decoration: const InputDecoration(
                      labelText: "Description / Payee",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (!item.isSelected) return null;
                      if (v == null || v.trim().isEmpty) return "Enter description";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Type and Category Row
                  Row(
                    children: [
                      // Type Picker
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Type",
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          initialValue: item.transactionType,
                          items: const [
                            DropdownMenuItem(value: 'expense', child: Text("Expense")),
                            DropdownMenuItem(value: 'investment', child: Text("Invest")),
                            DropdownMenuItem(value: 'owe', child: Text("I Owe")),
                            DropdownMenuItem(value: 'owed', child: Text("Owed")),
                          ],
                          onChanged: (val) {
                            setState(() {
                              item.transactionType = val!;
                            });
                          },
                        ),
                      ),
                      // Category Picker (only active for 'expense' type)
                      if (item.transactionType == 'expense') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Category",
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            initialValue: categories.any((c) => c.name == item.category)
                                ? item.category
                                : (categories.isNotEmpty ? categories.first.name : null),
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat.name,
                                child: Row(
                                  children: [
                                    Icon(
                                      IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                                      color: Color(cat.colorValue),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                item.category = val!;
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBottomBar(
    ThemeData theme,
    int selectedCount,
    double totalAmount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$selectedCount of ${_items.length} Selected",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total: \$${totalAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isImporting ? null : _importSelected,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      "Import Selected",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
