import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  final GroceryItem? existingItem;

  const NewItem({super.key, this.existingItem});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  late String _enteredName;
  late int _enteredQuantity;
  late Category _selectedCategory;
  var _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _enteredName = widget.existingItem!.name;
      _enteredQuantity = widget.existingItem!.quantity;
      _selectedCategory = widget.existingItem!.category;
    } else {
      _enteredName = '';
      _enteredQuantity = 1;
      _selectedCategory = categories[Categories.vegetables]!;
    }
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });

      final url = widget.existingItem == null
          ? Uri.https(
              'flutter-prep-72299-default-rtdb.firebaseio.com',
              'shopping-list.json',
            )
          : Uri.https(
              'flutter-prep-72299-default-rtdb.firebaseio.com',
              'shopping-list/${widget.existingItem!.id}.json',
            );

      final response = widget.existingItem == null
          ? await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'name': _enteredName,
                'quantity': _enteredQuantity,
                'category': _selectedCategory.title,
              }),
            )
          : await http.patch(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'name': _enteredName,
                'quantity': _enteredQuantity,
                'category': _selectedCategory.title,
              }),
            );

      final Map<String, dynamic> resData = json.decode(response.body);

      if (!mounted) return;

      Navigator.of(context).pop(
        GroceryItem(
          id: widget.existingItem?.id ?? resData['name'],
          name: _enteredName,
          quantity: _enteredQuantity,
          category: _selectedCategory,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.existingItem == null ? 'Add a new item' : 'Edit item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name input field.
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(label: Text('Name')),
                initialValue: _enteredName,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      value.length > 50) {
                    return 'Must be between 1 and 50 characters.';
                  }
                  return null;
                },
                onSaved: (value) => _enteredName = value!,
              ),
              // Row with quantity and category selection.
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration:
                          const InputDecoration(label: Text('Quantity')),
                      keyboardType: TextInputType.number,
                      initialValue: _enteredQuantity.toString(),
                      validator: (value) {
                        if (value == null ||
                            int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Must be a valid positive number.';
                        }
                        return null;
                      },
                      onSaved: (value) => _enteredQuantity = int.parse(value!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 6),
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Reset and Add/Update button row.
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () => _formKey.currentState!.reset(),
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : Text(widget.existingItem == null
                            ? 'Add Item'
                            : 'Update Item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
