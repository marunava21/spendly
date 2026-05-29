import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/providers/expense_provider.dart';
import 'package:spendly/providers/category_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  const AddExpenseScreen({super.key, this.expense});

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
  final _conversionRateController = TextEditingController(text: '1.0');

  String _transactionType = 'expense'; // 'expense', 'owe', 'owed', 'investment'
  String? _selectedCategory;
  late DateTime _selectedDate;
  String _selectedCurrencyCode = 'SGD';
  String _selectedCurrencySymbol = '\$';
  String? _invoicePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final e = widget.expense!;
      _transactionType = e.transactionType;
      _selectedCategory = (e.category == 'IOU' || e.category == 'Investment') ? null : e.category;
      _selectedDate = e.date;
      _selectedCurrencyCode = e.currency;
      _conversionRateController.text = e.conversionRate.toString();
      _amountController.text = (e.originalAmount ?? e.amount).toString();
      _noteController.text = e.note ?? '';
      _personNameController.text = e.personName ?? '';
      _brokerNameController.text = e.brokerName ?? '';
      _companyNameController.text = e.companyName ?? '';
      _invoicePath = e.invoicePath;
    } else {
      _selectedDate = context.read<ExpenseProvider>().selectedDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _personNameController.dispose();
    _brokerNameController.dispose();
    _companyNameController.dispose();
    _conversionRateController.dispose();
    super.dispose();
  }

  Future<void> _pickInvoicePhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Choose Document (PDF)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
        setState(() {
          _invoicePath = savedImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _getPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
        final savedFile = await file.copy('${appDir.path}/$fileName');
        setState(() {
          _invoicePath = savedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking PDF: $e')),
        );
      }
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      if (_transactionType == 'expense' && _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      final originalAmount = double.parse(_amountController.text);
      double conversionRate = 1.0;
      if (_selectedCurrencyCode != 'SGD') {
        conversionRate = double.tryParse(_conversionRateController.text) ?? 1.0;
      }
      final amount = originalAmount / conversionRate;

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

      if (widget.expense != null) {
        final updatedExpense = widget.expense!.copyWith(
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
          currency: _selectedCurrencyCode,
          conversionRate: conversionRate,
          originalAmount: originalAmount,
          invoicePath: _invoicePath,
        );
        context.read<ExpenseProvider>().updateExpense(updatedExpense);
      } else {
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
              currency: _selectedCurrencyCode,
              conversionRate: conversionRate,
              originalAmount: originalAmount,
              invoicePath: _invoicePath,
            );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.expense != null ? 'Edit ' : 'Add ';
    if (_transactionType == 'owe' || _transactionType == 'owed') {
      title += 'IOU';
    } else if (_transactionType == 'investment') {
      title += 'Investment';
    } else {
      title += 'Expense';
    }

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () {
                          showCurrencyPicker(
                            context: context,
                            showFlag: true,
                            showCurrencyName: true,
                            showCurrencyCode: true,
                            onSelect: (Currency currency) {
                              setState(() {
                                _selectedCurrencyCode = currency.code;
                                _selectedCurrencySymbol = currency.symbol;
                              });
                            },
                          );
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_selectedCurrencyCode),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '$_selectedCurrencySymbol ',
                          border: const OutlineInputBorder(),
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
                    ),
                  ],
                ),
                if (_selectedCurrencyCode != 'SGD') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _conversionRateController,
                    decoration: InputDecoration(
                      labelText: 'Conversion Rate (1 SGD = ? $_selectedCurrencyCode)',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a rate';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Please enter a valid rate';
                      }
                      return null;
                    },
                  ),
                ],
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
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickInvoicePhoto,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Add Attachment'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_invoicePath != null) ...[
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _invoicePath!.toLowerCase().endsWith('.pdf')
                            ? SizedBox(
                                height: 300,
                                width: double.infinity,
                                child: SfPdfViewer.file(
                                  File(_invoicePath!),
                                  canShowScrollHead: false,
                                ),
                              )
                            : GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.black87,
                                      insetPadding: EdgeInsets.zero,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          InteractiveViewer(
                                            panEnabled: true,
                                            minScale: 0.5,
                                            maxScale: 4,
                                            child: Image.file(File(_invoicePath!)),
                                          ),
                                          Positioned(
                                            top: 40,
                                            right: 20,
                                            child: IconButton(
                                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                              onPressed: () => Navigator.of(context).pop(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Image.file(
                                  File(_invoicePath!),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _invoicePath = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.expense != null ? 'Update Transaction' : 'Save Transaction',
                    style: const TextStyle(fontSize: 18),
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
