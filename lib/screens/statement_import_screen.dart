import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:spendly/utils/gemini_parser.dart';
import 'package:spendly/utils/statement_parser.dart';
import 'package:spendly/screens/import_review_screen.dart';

class StatementImportScreen extends StatefulWidget {
  const StatementImportScreen({super.key});

  @override
  State<StatementImportScreen> createState() => _StatementImportScreenState();
}

class _StatementImportScreenState extends State<StatementImportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();

  // CSV State
  String? _csvFileName;
  String? _csvContent;
  List<List<dynamic>> _csvRows = [];
  bool _hasHeader = true;

  int _dateColIndex = 0;
  int _descColIndex = 1;
  int _amountColIndex = 2;

  bool _isExtractingPDF = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // Pick File (CSV or PDF)
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;

        if (file.extension?.toLowerCase() == 'pdf') {
          setState(() => _isExtractingPDF = true);
          try {
            final parsedTransactions = await GeminiParser.extractDebitsFromPDF(file.bytes!);
            
            if (!mounted) return;
            
            if (parsedTransactions.isEmpty) {
              _showErrorSnackBar("No debit transactions found by AI.");
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImportReviewScreen(transactions: parsedTransactions),
              ),
            );
          } catch (e) {
            if (mounted) _showErrorSnackBar("AI Extraction Failed: $e");
          } finally {
            if (mounted) setState(() => _isExtractingPDF = false);
          }
        } else {
          final content = utf8.decode(file.bytes!);
          final rows = const CsvToListConverter().convert(content);

          if (rows.isEmpty) {
            _showErrorSnackBar("The selected CSV file is empty");
            return;
          }

          setState(() {
            _csvFileName = file.name;
            _csvContent = content;
            _csvRows = rows;

            // Attempt to auto-detect indices based on headers
            _autoDetectColumns(rows.first);
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar("Failed to read file: $e");
    }
  }

  void _autoDetectColumns(List<dynamic> headers) {
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toString().toLowerCase();
      if (header.contains('date')) {
        _dateColIndex = i;
      } else if (header.contains('desc') || header.contains('note') || header.contains('particular') || header.contains('payee')) {
        _descColIndex = i;
      } else if (header.contains('amount') || header.contains('val') || header.contains('debit') || header.contains('transact')) {
        _amountColIndex = i;
      }
    }

    // fallback check if indices are equal
    if (_dateColIndex == _descColIndex || _descColIndex == _amountColIndex) {
      if (headers.isNotEmpty) _dateColIndex = 0;
      if (headers.length > 1) _descColIndex = 1;
      if (headers.length > 2) _amountColIndex = 2;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Handle CSV Import Proceed
  void _proceedWithCSV() {
    if (_csvContent == null || _csvRows.isEmpty) return;

    final parsed = StatementParser.parseCsv(
      _csvContent!,
      dateColIndex: _dateColIndex,
      descColIndex: _descColIndex,
      amountColIndex: _amountColIndex,
      hasHeader: _hasHeader,
    );

    if (parsed.isEmpty) {
      _showErrorSnackBar("Could not parse any valid transactions from the CSV. Check your column mapping.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImportReviewScreen(transactions: parsed),
      ),
    );
  }

  // Handle Text Copy Paste Import Proceed
  void _proceedWithText() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showErrorSnackBar("Please paste some statement text first");
      return;
    }

    final lines = text.split('\n');
    final parsed = <ParsedTransaction>[];

    for (var line in lines) {
      final tx = StatementParser.parseLine(line);
      if (tx != null) {
        parsed.add(tx);
      }
    }

    if (parsed.isEmpty) {
      _showErrorSnackBar("Could not auto-detect any transactions from the text. Check formatting.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImportReviewScreen(transactions: parsed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Statement'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(icon: Icon(Icons.insert_drive_file), text: "Upload File"),
            Tab(icon: Icon(Icons.paste), text: "Paste Text"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCSVTab(theme),
          _buildTextTab(theme),
        ],
      ),
    );
  }

  Widget _buildCSVTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_csvFileName == null)
            GestureDetector(
              onTap: _isExtractingPDF ? null : _pickFile,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.primary.withAlpha(102), width: 2, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isExtractingPDF)
                      const CircularProgressIndicator()
                    else ...[
                      Icon(Icons.cloud_upload_outlined, size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        "Tap to choose a CSV or PDF file",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Supports standard bank statement exports",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            // File Selected Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.description, color: theme.colorScheme.primary, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _csvFileName!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_csvRows.length} rows found",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _csvFileName = null;
                          _csvContent = null;
                          _csvRows = [];
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Header Toggle & Mapping Configuration
            const Text(
              "Column Mapping Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text("First row is column headers"),
              subtitle: const Text("Skip the first row of CSV data when parsing"),
              value: _hasHeader,
              activeThumbColor: theme.colorScheme.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _hasHeader = val);
              },
            ),
            const Divider(height: 24),
            // Mapping Dropdowns
            _buildMappingDropdown("Date Column", _dateColIndex, (index) {
              setState(() => _dateColIndex = index!);
            }),
            const SizedBox(height: 12),
            _buildMappingDropdown("Description/Note Column", _descColIndex, (index) {
              setState(() => _descColIndex = index!);
            }),
            const SizedBox(height: 12),
            _buildMappingDropdown("Amount Column", _amountColIndex, (index) {
              setState(() => _amountColIndex = index!);
            }),
            const SizedBox(height: 24),
            // Horizontal Data Preview
            if (_csvRows.isNotEmpty) ...[
              const Text(
                "Data Preview (First 3 Rows)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(theme.colorScheme.primaryContainer.withAlpha(76)),
                      columnSpacing: 24,
                      columns: List.generate(
                        _csvRows.first.length,
                        (i) => DataColumn(
                          label: Text(
                            _hasHeader ? _csvRows.first[i].toString() : "Col $i",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      rows: List.generate(
                        _csvRows.length > 4 ? 3 : _csvRows.length - (_hasHeader ? 1 : 0),
                        (rowIndex) {
                          final actualRowIndex = rowIndex + (_hasHeader ? 1 : 0);
                          if (actualRowIndex >= _csvRows.length) return const DataRow(cells: []);
                          final row = _csvRows[actualRowIndex];
                          return DataRow(
                            cells: List.generate(
                              row.length,
                              (cellIndex) => DataCell(
                                Text(row[cellIndex].toString()),
                              ),
                            ),
                          );
                        },
                      ).where((row) => row.cells.isNotEmpty).toList(),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _proceedWithCSV,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Review Transactions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMappingDropdown(String label, int selectedIndex, ValueChanged<int?> onChanged) {
    if (_csvRows.isEmpty) return const SizedBox.shrink();
    final headers = _csvRows.first;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            initialValue: selectedIndex,
            items: List.generate(
              headers.length,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  _hasHeader ? "${headers[i]} (Col $i)" : "Column $i",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTextTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Paste Statement Lines",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            "Paste raw transaction lines copied directly from your online banking portal or PDF statement. We will auto-extract dates, amounts, and notes.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Example Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Example formats detected:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 6),
                Text("22 May 2026   STARBUCKS COFFEE   -SGD 8.50", style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey.shade700)),
                Text("2026/05/20   GRAB RIDE TAXI   12.00", style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey.shade700)),
                Text("May 19, 2026   NETFLIX BILLING   \$14.98", style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _textController,
            maxLines: 12,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: "Paste bank statement transaction lines here...\nOne transaction per line.",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _proceedWithText,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Review Transactions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
