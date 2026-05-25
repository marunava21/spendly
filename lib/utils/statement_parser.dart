import 'package:csv/csv.dart';

class ParsedTransaction {
  DateTime date;
  String note;
  double amount;
  String category;
  String transactionType;

  ParsedTransaction({
    required this.date,
    required this.note,
    required this.amount,
    this.category = 'Other',
    this.transactionType = 'expense',
  });
}

class StatementParser {
  /// Guess category based on transaction description note
  static String guessCategory(String note) {
    final lowercaseNote = note.toLowerCase();

    if (lowercaseNote.contains('grab') ||
        lowercaseNote.contains('uber') ||
        lowercaseNote.contains('taxi') ||
        lowercaseNote.contains('mrt') ||
        lowercaseNote.contains('bus') ||
        lowercaseNote.contains('transit') ||
        lowercaseNote.contains('comfortdelgro') ||
        lowercaseNote.contains('gojek')) {
      return 'Transport';
    }

    if (lowercaseNote.contains('mcdonald') ||
        lowercaseNote.contains('starbucks') ||
        lowercaseNote.contains('restaurant') ||
        lowercaseNote.contains('food') ||
        lowercaseNote.contains('cafe') ||
        lowercaseNote.contains('deli') ||
        lowercaseNote.contains('pizza') ||
        lowercaseNote.contains('sushi') ||
        lowercaseNote.contains('eats') ||
        lowercaseNote.contains('kfc') ||
        lowercaseNote.contains('burger') ||
        lowercaseNote.contains('kopitiam') ||
        lowercaseNote.contains('bakery') ||
        lowercaseNote.contains('dining')) {
      return 'Food';
    }

    if (lowercaseNote.contains('netflix') ||
        lowercaseNote.contains('cinema') ||
        lowercaseNote.contains('spotify') ||
        lowercaseNote.contains('movie') ||
        lowercaseNote.contains('steam') ||
        lowercaseNote.contains('game') ||
        lowercaseNote.contains('disney') ||
        lowercaseNote.contains('theatre') ||
        lowercaseNote.contains('concert') ||
        lowercaseNote.contains('event') ||
        lowercaseNote.contains('pub') ||
        lowercaseNote.contains('bar') ||
        lowercaseNote.contains('club')) {
      return 'Entertainment';
    }

    if (lowercaseNote.contains('amazon') ||
        lowercaseNote.contains('shopee') ||
        lowercaseNote.contains('lazada') ||
        lowercaseNote.contains('mall') ||
        lowercaseNote.contains('store') ||
        lowercaseNote.contains('target') ||
        lowercaseNote.contains('walmart') ||
        lowercaseNote.contains('clothing') ||
        lowercaseNote.contains('fashion') ||
        lowercaseNote.contains('uniqlo') ||
        lowercaseNote.contains('supermarket') ||
        lowercaseNote.contains('fairprice') ||
        lowercaseNote.contains('cold storage') ||
        lowercaseNote.contains('h&m') ||
        lowercaseNote.contains('zara') ||
        lowercaseNote.contains('grocery')) {
      return 'Shopping';
    }

    if (lowercaseNote.contains('bill') ||
        lowercaseNote.contains('telecom') ||
        lowercaseNote.contains('singtel') ||
        lowercaseNote.contains('starhub') ||
        lowercaseNote.contains('m1') ||
        lowercaseNote.contains('utility') ||
        lowercaseNote.contains('power') ||
        lowercaseNote.contains('water') ||
        lowercaseNote.contains('sp group') ||
        lowercaseNote.contains('insurance') ||
        lowercaseNote.contains('tax') ||
        lowercaseNote.contains('telco') ||
        lowercaseNote.contains('mobile') ||
        lowercaseNote.contains('broadband')) {
      return 'Bills';
    }

    return 'Other';
  }

  /// Guess transaction type based on transaction description note
  static String guessTransactionType(String note) {
    final lowercaseNote = note.toLowerCase();
    if (lowercaseNote.contains('invest') ||
        lowercaseNote.contains('broker') ||
        lowercaseNote.contains('stocks') ||
        lowercaseNote.contains('crypto') ||
        lowercaseNote.contains('binance') ||
        lowercaseNote.contains('fidelity') ||
        lowercaseNote.contains('vanguard') ||
        lowercaseNote.contains('syfe') ||
        lowercaseNote.contains('stashaway') ||
        lowercaseNote.contains('dividends') ||
        lowercaseNote.contains('shares')) {
      return 'investment';
    }
    return 'expense';
  }

  /// Tries to parse date string in common bank formats
  static DateTime? tryParseDate(String dateStr) {
    dateStr = dateStr.trim().replaceAll(RegExp(r'\s+'), ' ');

    // 1. Try standard parse (ISO YYYY-MM-DD)
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) return parsed;

    // 2. Try DD/MM/YYYY or DD-MM-YYYY
    final dmyRegex = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})$');
    if (dmyRegex.hasMatch(dateStr)) {
      final match = dmyRegex.firstMatch(dateStr)!;
      int day = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int year = int.parse(match.group(3)!);
      if (year < 100) {
        year += 2000;
      }
      try {
        return DateTime(year, month, day);
      } catch (_) {}
    }

    // 3. Try YYYY/MM/DD
    final ymdRegex = RegExp(r'^(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})$');
    if (ymdRegex.hasMatch(dateStr)) {
      final match = ymdRegex.firstMatch(dateStr)!;
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      try {
        return DateTime(year, month, day);
      } catch (_) {}
    }

    // 4. Try textual month name: "22 May 2026", "22 May 26", "May 22, 2026"
    final months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      'january': 1, 'february': 2, 'march': 3, 'april': 4, 'june': 6,
      'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12
    };

    final lowerStr = dateStr.toLowerCase();

    // "22 May 2026" or "22 May 26"
    final textDateRegex1 = RegExp(r'^(\d{1,2})\s+([a-z]+)\s+(\d{2,4})$');
    if (textDateRegex1.hasMatch(lowerStr)) {
      final match = textDateRegex1.firstMatch(lowerStr)!;
      int day = int.parse(match.group(1)!);
      String monthStr = match.group(2)!;
      int year = int.parse(match.group(3)!);
      if (year < 100) year += 2000;

      if (months.containsKey(monthStr)) {
        int month = months[monthStr]!;
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    // "May 22 2026" or "May 22, 2026"
    final textDateRegex2 = RegExp(r'^([a-z]+)\s+(\d{1,2}),?\s+(\d{2,4})$');
    if (textDateRegex2.hasMatch(lowerStr)) {
      final match = textDateRegex2.firstMatch(lowerStr)!;
      String monthStr = match.group(1)!;
      int day = int.parse(match.group(2)!);
      int year = int.parse(match.group(3)!);
      if (year < 100) year += 2000;

      if (months.containsKey(monthStr)) {
        int month = months[monthStr]!;
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    return null;
  }

  /// Parses a single copy-pasted string line from a bank statement
  static ParsedTransaction? parseLine(String line) {
    line = line.trim();
    if (line.isEmpty) return null;

    // Search for a date pattern
    final datePatterns = [
      RegExp(r'\d{4}[/\-]\d{1,2}[/\-]\d{1,2}'),
      RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}'),
      RegExp(r'\d{1,2}\s+[A-Za-z]{3,}\s+\d{2,4}'),
      RegExp(r'[A-Za-z]{3,}\s+\d{1,2},?\s+\d{2,4}'),
    ];

    String? foundDateStr;
    for (var pattern in datePatterns) {
      final match = pattern.stringMatch(line);
      if (match != null) {
        foundDateStr = match;
        break;
      }
    }

    if (foundDateStr == null) return null;
    final parsedDate = tryParseDate(foundDateStr);
    if (parsedDate == null) return null;

    String lineWithoutDate = line.replaceFirst(foundDateStr, '').trim();

    // Look for decimals: standard currency amounts like -12.50, $12.50, SGD 15, etc.
    // We match any number with optional currency signs and optional negative sign.
    // Decimals are preferred.
    final amountRegex = RegExp(r'-?\s*(?:\$|SGD|S\$)?\s*\d+(?:\.\d{1,2})?');
    final matches = amountRegex.allMatches(lineWithoutDate).toList();
    if (matches.isEmpty) return null;

    // The amount is usually the last number in the line (after the description)
    final amountMatch = matches.last;
    final rawAmountStr = amountMatch.group(0)!;

    // Clean description must exclude the amount
    String cleanAmountStr = rawAmountStr.replaceAll(RegExp(r'[^\d\.\-]'), '');
    double? parsedAmount = double.tryParse(cleanAmountStr);
    if (parsedAmount == null) return null;

    double finalAmount = parsedAmount.abs();
    if (finalAmount == 0) return null;

    String note = lineWithoutDate.replaceFirst(rawAmountStr, '').trim();
    note = note.replaceAll(RegExp(r'\s+'), ' ').trim();
    note = note.replaceAll(RegExp(r'^[\s\-,\t]+|[\s\-,\t]+$'), '');

    if (note.isEmpty) {
      note = "Imported Transaction";
    }

    return ParsedTransaction(
      date: parsedDate,
      note: note,
      amount: finalAmount,
      category: guessCategory(note),
      transactionType: guessTransactionType(note),
    );
  }

  /// Parses CSV raw text into a list of parsed transactions
  static List<ParsedTransaction> parseCsv(
    String csvContent, {
    required int dateColIndex,
    required int descColIndex,
    required int amountColIndex,
    bool hasHeader = true,
  }) {
    final normalizedContent = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final list = const CsvToListConverter(eol: '\n').convert(normalizedContent);
    final results = <ParsedTransaction>[];

    int startIndex = hasHeader ? 1 : 0;
    for (int i = startIndex; i < list.length; i++) {
      final row = list[i];
      if (row.length <= dateColIndex ||
          row.length <= descColIndex ||
          row.length <= amountColIndex) {
        continue;
      }

      final rawDate = row[dateColIndex].toString();
      final rawDesc = row[descColIndex].toString();
      final rawAmount = row[amountColIndex].toString();

      final parsedDate = tryParseDate(rawDate);
      if (parsedDate == null) continue;

      // Clean amount
      String cleanAmountStr = rawAmount.replaceAll(RegExp(r'[^\d\.\-]'), '');
      double? amount = double.tryParse(cleanAmountStr);
      if (amount == null) continue;

      amount = amount.abs();
      if (amount == 0) continue;

      final desc = rawDesc.trim();
      results.add(ParsedTransaction(
        date: parsedDate,
        note: desc.isEmpty ? "CSV Imported Transaction" : desc,
        amount: amount,
        category: guessCategory(desc),
        transactionType: guessTransactionType(desc),
      ));
    }

    return results;
  }
}
