import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:spendly/providers/expense_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<DateRangeFilter>(
            onSelected: (filter) {
              context.read<ExpenseProvider>().setFilter(filter);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: DateRangeFilter.daily,
                child: Text('Daily'),
              ),
              PopupMenuItem(
                value: DateRangeFilter.thisWeek,
                child: Text('This Week'),
              ),
              PopupMenuItem(
                value: DateRangeFilter.thisMonth,
                child: Text('This Month'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.expenses.isEmpty) {
            return const Center(child: Text('No data for analytics.'));
          }

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Expenses by Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 1,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: provider.categoryTotals.entries.map((e) {
                      return PieChartSectionData(
                        value: e.value,
                        title: e.key,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        color: _getColorForCategory(e.key),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 8.0, bottom: 16.0),
                  child: _buildBarChart(context, provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, ExpenseProvider provider) {
    // Sort the daily totals chronologically
    final sortedKeys = provider.dailyTotals.keys.toList()..sort();
    
    // We will map the sorted keys to an index for the BarChart X-axis
    List<BarChartGroupData> barGroups = [];
    double maxAmount = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final amount = provider.dailyTotals[key]!;
      if (amount > maxAmount) maxAmount = amount;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Theme.of(context).colorScheme.primary,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxAmount * 1.2, // add some headroom
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                  // The key is 'yyyy-MM-dd', parse it and show 'MM/dd'
                  final date = DateTime.parse(sortedKeys[value.toInt()]);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) return const Text('');
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      case 'Shopping':
        return Colors.pink;
      case 'Bills':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }
}
