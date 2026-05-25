import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/models/expense.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isOwe = expense.transactionType == 'owe';
    bool isOwed = expense.transactionType == 'owed';
    bool isInvestment = expense.transactionType == 'investment';
    bool isExpense = expense.transactionType == 'expense';

    String titleText = expense.category;
    if (isOwe) titleText = 'You owe ${expense.personName ?? "Someone"}';
    if (isOwed) titleText = '${expense.personName ?? "Someone"} owes you';
    if (isInvestment) titleText = '${expense.companyName ?? "Asset"} via ${expense.brokerName ?? "Broker"}';

    Color amountColor = Theme.of(context).colorScheme.primary;
    if (isOwe) amountColor = Colors.red;
    if (isOwed) amountColor = Colors.green;
    if (isInvestment) amountColor = Colors.deepPurple;

    IconData avatarIcon = Icons.category;
    if (isOwe) avatarIcon = Icons.arrow_upward;
    if (isOwed) avatarIcon = Icons.arrow_downward;
    if (isInvestment) avatarIcon = Icons.trending_up;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isExpense 
              ? Theme.of(context).colorScheme.primaryContainer
              : amountColor.withValues(alpha: 0.2),
          child: isExpense 
              ? Text(
                  expense.category[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Icon(avatarIcon, color: amountColor),
        ),
        title: Text(
          titleText,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isExpense ? Colors.black87 : amountColor,
          ),
        ),
        subtitle: Text(
          expense.note ?? DateFormat('hh:mm a').format(expense.date),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
