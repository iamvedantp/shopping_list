import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode currentTheme;

  const GroceryList({
    super.key,
    required this.onToggleTheme,
    required this.currentTheme,
  });

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'flutter-prep-72299-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == item.value['category'],
            )
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _updateItem(GroceryItem item) async {
    final updatedItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => NewItem(existingItem: item),
      ),
    );

    if (updatedItem == null) return;

    setState(() {
      final index = _groceryItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _groceryItems[index] = updatedItem;
      }
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      'flutter-prep-72299-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      // Optional: Show error message and re-add item if delete fails.
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'));

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Card(
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _updateItem(_groceryItems[index]),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeItem(_groceryItems[index]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.currentTheme == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
