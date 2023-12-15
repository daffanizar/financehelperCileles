import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:inti_apps/database/sql_helper.dart';
import 'package:inti_apps/pages/cobagabung.dart';
import 'package:inti_apps/pages/home_page.dart';
import 'package:inti_apps/pages/main_page.dart';

class AddStockForm extends StatefulWidget {
  bool edit = false;
  AddStockForm({bool? edit}) : edit = edit ?? false;
  @override
  _AddStockFormState createState() => _AddStockFormState();
}

class _AddStockFormState extends State<AddStockForm> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _journals = [];
  List<String> _itemNames = [];

  bool _isLoading = true;
  String? _selectedItemName;

  void _refreshJournals() async {
    final data = await getItems();
    setState(() {
      _journals = data;
      _itemNames = _journals.map((item) => item['name'] as String).toList();
      _isLoading = false;
    });
  }

  Future<void> _addItem() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      int quantity = int.parse(_quantityController.text);
      double buy_cost = double.parse(_buyCostController.text);
      double sell_cost = double.parse(_sellCostController.text);

      if (_selectedItemName != null) {
        try {
          await SQLHelper.UpdateItem(
              _selectedItemName!, name, quantity, buy_cost, sell_cost);
          setState(() {
            _selectedItemName = null; // Reset selected item after update
          });
        } catch (e) {
          print('Error updating item: $e');
        }
      } else {
        try {
          await SQLHelper.createItem(name, quantity, buy_cost, sell_cost);
        } catch (e) {
          print('Error creating item: $e');
        }
      }

      _refreshJournals();
      print("number of items ${_journals.length}");
    }
  }

  void _loadItemData(String itemName) {
    // Find the item by name in the list and set the form fields
    var selectedItem = _journals.firstWhere((item) => item['name'] == itemName);
    _nameController.text = selectedItem['name'];
    _quantityController.text = selectedItem['stock'].toString();
    _buyCostController.text = selectedItem['buy_cost'].toString();
    _sellCostController.text = selectedItem['sell_cost'].toString();
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals();
    print("number of items ${_journals.length}");
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _buyCostController = TextEditingController();
  final TextEditingController _sellCostController = TextEditingController();

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.edit ? 'Tambah Stock' : 'Tambah Barang'),
        backgroundColor: Colors.amber, // Set the background color to amber
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.edit)
                DropdownButtonFormField<String>(
                  value: _selectedItemName,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedItemName = newValue;
                      if (_selectedItemName != null) {
                        // Load data for the selected item
                        _loadItemData(_selectedItemName!);
                      }
                    });
                  },
                  items: _itemNames.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  hint: Text('Pilih Barang'),
                ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nama barang'),
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tolong masukkan nama barang';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Jumlah'),
                controller: _quantityController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tolong masukkan jumlah barang';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Harga Jual'),
                controller: _sellCostController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan harga jual';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Harga beli'),
                controller: _buyCostController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tolong masukkan harga beli';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Save Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _addItem();
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.amber, // Set the background color to amber
                ),
                child: Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
