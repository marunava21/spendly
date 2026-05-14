import 'package:flutter/material.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/providers/expense_provider.dart';
import 'package:spendly/widgets/expense_list_item.dart';

class ExpenseSearchDelegate extends SearchDelegate {
  final ExpenseProvider provider;

  ExpenseSearchDelegate(this.provider);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search by category or note'));
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    // Note: To avoid mutating the provider's main state, we should use a temporary fetch.
    // However, since we added `searchExpenses` to ExpenseRepository, we can just use that.
    return FutureBuilder<List<Expense>>(
      // We assume the provider has a reference to the repository, but since it's private,
      // we added a `search` method to the provider. Wait, `provider.search` modifies the provider state.
      // We will just do the search and manage the state locally if possible.
      // Actually, I can just use provider._repository.searchExpenses... Wait, it's private.
      // So I will update ExpenseProvider to expose `searchExpenses(query)` that RETURNS a list.
      future: provider.searchExpensesReturnList(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error searching expenses'));
        }
        
        final expenses = snapshot.data ?? [];
        
        if (expenses.isEmpty) {
          return const Center(child: Text('No matching expenses found'));
        }

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return ExpenseListItem(
              expense: expense,
              onDelete: () {
                provider.deleteExpense(expense.id);
                // Simple hack to trigger rebuild
                query = query;
              },
            );
          },
        );
      },
    );
  }
}
