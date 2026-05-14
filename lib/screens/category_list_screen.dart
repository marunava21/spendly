import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/models/category.dart';
import 'package:spendly/providers/category_provider.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }
          return ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final cat = provider.categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(cat.colorValue).withAlpha(51),
                  child: Icon(
                    IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                    color: Color(cat.colorValue),
                  ),
                ),
                title: Text(cat.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => provider.deleteCategory(cat.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategorySheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddCategorySheet(),
    );
  }
}

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({super.key});
  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  final List<int> _colors = [
    0xFFFF9800, 0xFF2196F3, 0xFF9C27B0, 0xFFE91E63, 0xFFF44336, 0xFF009688, 0xFF4CAF50, 0xFFFFC107
  ];
  final List<IconData> _icons = [
    Icons.restaurant, Icons.directions_car, Icons.movie, Icons.shopping_bag, 
    Icons.receipt, Icons.category, Icons.pets, Icons.flight, Icons.home, Icons.fitness_center
  ];

  int _selectedColor = 0xFFFF9800;
  IconData _selectedIcon = Icons.restaurant;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newCat = ExpenseCategory(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        colorValue: _selectedColor,
        iconCodePoint: _selectedIcon.codePoint,
      );
      context.read<CategoryProvider>().addCategory(newCat);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            const Text('Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors.map((c) => GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: CircleAvatar(
                  backgroundColor: Color(c),
                  radius: 16,
                  child: _selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _icons.map((i) => GestureDetector(
                onTap: () => setState(() => _selectedIcon = i),
                child: CircleAvatar(
                  backgroundColor: _selectedIcon == i ? Colors.grey.shade300 : Colors.transparent,
                  radius: 20,
                  child: Icon(i, color: Colors.black),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
