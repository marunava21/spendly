import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/utils/statement_parser.dart';

void main() {
  group('StatementParser tests', () {
    test('tryParseDate parses various date formats correctly', () {
      expect(StatementParser.tryParseDate('2026-05-22'), equals(DateTime(2026, 5, 22)));
      expect(StatementParser.tryParseDate('22/05/2026'), equals(DateTime(2026, 5, 22)));
      expect(StatementParser.tryParseDate('22-05-2026'), equals(DateTime(2026, 5, 22)));
      expect(StatementParser.tryParseDate('22 May 2026'), equals(DateTime(2026, 5, 22)));
      expect(StatementParser.tryParseDate('May 22, 2026'), equals(DateTime(2026, 5, 22)));
      expect(StatementParser.tryParseDate('22 May 26'), equals(DateTime(2026, 5, 22)));
      expect(StatementParser.tryParseDate('invalid-date'), isNull);
    });

    test('guessCategory maps notes to correct categories', () {
      expect(StatementParser.guessCategory('Grab ride to work'), equals('Transport'));
      expect(StatementParser.guessCategory('McDonalds lunch'), equals('Food'));
      expect(StatementParser.guessCategory('Netflix monthly bill'), equals('Entertainment'));
      expect(StatementParser.guessCategory('Amazon SG shopping'), equals('Shopping'));
      expect(StatementParser.guessCategory('SP Group utility bill'), equals('Bills'));
      expect(StatementParser.guessCategory('Unknown transaction description'), equals('Other'));
    });

    test('guessTransactionType maps keywords to investment or expense', () {
      expect(StatementParser.guessTransactionType('Vanguard ETF Buy'), equals('investment'));
      expect(StatementParser.guessTransactionType('Binance Crypto BTC'), equals('investment'));
      expect(StatementParser.guessTransactionType('Dinner with friends'), equals('expense'));
    });

    test('parseLine parses single raw copy-pasted string correctly', () {
      final line1 = '2026-05-22  MCDONALDS SINGAPORE   -SGD 15.40';
      final tx1 = StatementParser.parseLine(line1);
      expect(tx1, isNotNull);
      expect(tx1!.date, equals(DateTime(2026, 5, 22)));
      expect(tx1.note, equals('MCDONALDS SINGAPORE'));
      expect(tx1.amount, equals(15.40));
      expect(tx1.category, equals('Food'));
      expect(tx1.transactionType, equals('expense'));

      final line2 = '22/05/2026 GRAB RIDE TAXI 8.50';
      final tx2 = StatementParser.parseLine(line2);
      expect(tx2, isNotNull);
      expect(tx2!.date, equals(DateTime(2026, 5, 22)));
      expect(tx2.note, equals('GRAB RIDE TAXI'));
      expect(tx2.amount, equals(8.50));
      expect(tx2.category, equals('Transport'));
      expect(tx2.transactionType, equals('expense'));

      final line3 = 'May 20, 2026 STASHAWAY PORTFOLIO SGD 200.00';
      final tx3 = StatementParser.parseLine(line3);
      expect(tx3, isNotNull);
      expect(tx3!.date, equals(DateTime(2026, 5, 20)));
      expect(tx3.note, equals('STASHAWAY PORTFOLIO'));
      expect(tx3.amount, equals(200.00));
      expect(tx3.category, equals('Other')); // Custom type but category Investment parsed in UI
      expect(tx3.transactionType, equals('investment'));
    });

    test('parseCsv converts CSV format to parsed transactions', () {
      final csv = 'Date,Description,Amount,Type\n'
          '2026-05-22,McDonalds lunch,15.20,debit\n'
          '22/05/2026,Comfort taxi,23.50,debit\n'
          '2026-05-20,Vanguard Buy,500.00,investment';

      final results = StatementParser.parseCsv(
        csv,
        dateColIndex: 0,
        descColIndex: 1,
        amountColIndex: 2,
        hasHeader: true,
      );

      expect(results.length, equals(3));
      expect(results[0].date, equals(DateTime(2026, 5, 22)));
      expect(results[0].note, equals('McDonalds lunch'));
      expect(results[0].amount, equals(15.20));
      expect(results[0].category, equals('Food'));
      expect(results[0].transactionType, equals('expense'));

      expect(results[1].category, equals('Transport'));

      expect(results[2].note, equals('Vanguard Buy'));
      expect(results[2].transactionType, equals('investment'));
    });
  });
}
