import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:spendly/utils/statement_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiParser {
  // Using the API key provided from .env
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Extracts debit transactions from a PDF using Gemini Generative AI
  static Future<List<ParsedTransaction>> extractDebitsFromPDF(Uint8List pdfBytes) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
    );

    final prompt = TextPart('''
You are an expert OCR and financial data extraction model. 
Read the attached bank statement PDF. 
Extract all transaction records, but ONLY consider the debit amounts (money going out). Ignore credits, deposits, account summaries, and balances.
Return the data as a clean JSON array of objects. Each object must have exactly these keys:
- "date": The date of the transaction in YYYY-MM-DD format.
- "description": The merchant name or transaction description.
- "amount": The absolute positive number representing the debit amount.
Do not wrap the output in markdown code blocks like ```json, just return the raw JSON array.
''');

    final fileData = DataPart('application/pdf', pdfBytes);

    try {
      final response = await model.generateContent([
        Content.multi([prompt, fileData])
      ]);

      final text = response.text?.trim() ?? '[]';
      
      // Clean up markdown block if the model included it despite instructions
      String jsonStr = text;
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final List<ParsedTransaction> transactions = [];

      for (var item in jsonList) {
        final Map<String, dynamic> map = item as Map<String, dynamic>;
        final String dateStr = map['date']?.toString() ?? '';
        final String desc = map['description']?.toString() ?? 'Unknown';
        final String amountStr = map['amount']?.toString() ?? '0';

        final DateTime? parsedDate = StatementParser.tryParseDate(dateStr);
        if (parsedDate != null) {
          final double amount = double.tryParse(amountStr.replaceAll(RegExp(r'[^\d\.]'), '')) ?? 0.0;
          if (amount > 0) {
            // Apply auto-categorization
            final String category = StatementParser.guessCategory(desc);
            
            transactions.add(ParsedTransaction(
              date: parsedDate,
              note: desc, // Note is mapped to description
              amount: amount,
              category: category,
              transactionType: 'expense', // Forced to expense since it's a debit
            ));
          }
        }
      }

      return transactions;
    } catch (e) {
      throw Exception('Failed to extract transactions with AI: $e');
    }
  }
}
