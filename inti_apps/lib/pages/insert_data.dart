import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inti_apps/database/sql_helper.dart';
import 'package:inti_apps/pages/main_page.dart';

class Item {
  final int id;
  final String name;

  Item(this.id, this.name);
}

class InsertNew extends StatefulWidget {
  @override
  _InsertNewState createState() => _InsertNewState();
}

class _InsertNewState extends State<InsertNew> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _jumlahController = TextEditingController();
  int _selectedItemId = 0;
  List<Item> itemNames = [];
  List<Map<String, dynamic>> _journals = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _refreshJournals();
    });
  }

  void _refreshJournals() async {
    final data = await getItems();
    setState(() {
      _journals = data;
      _isLoading = false;

      itemNames = _journals.map((journal) {
        return Item(journal['id'], journal['name']);
      }).toList();

      _selectedItemId = itemNames.isNotEmpty ? itemNames[0].id : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Masukkan Transaksi', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedItemId,
                hint: Text('Select Item', style: GoogleFonts.montserrat()),
                onChanged: (value) {
                  setState(() {
                    _selectedItemId = value!;
                  });
                },
                items: itemNames.map((item) {
                  return DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name, style: GoogleFonts.montserrat()),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value == 0) {
                    return 'Please select the item';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  labelStyle: GoogleFonts.montserrat(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the quantity';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    int itemId = _selectedItemId;
                    int jumlah = int.parse(_jumlahController.text);

                    if (await _checkStockAvailability(itemId, jumlah)) {
                      double sellCost = _journals.firstWhere(
                          (journal) => journal['id'] == itemId)['sell_cost'];
                      double buyCost = _journals.firstWhere(
                          (journal) => journal['id'] == itemId)['buy_cost'];
                      double totalincome = sellCost * jumlah;
                      double profit = (sellCost - buyCost) * jumlah;

                      await SQLHelper.createTransaction(
                          itemId, jumlah, DateTime.now().toString());

                      await _updateFinance(totalincome, profit);
                      await _updateStock(itemId, jumlah);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainPage(),
                        ),
                      );
                    } else {
                      _showStockUnavailableWarning();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.amber,
                ),
                child: Text('Save', style: GoogleFonts.montserrat()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateFinance(double totalCost, double profit) async {
    List<Map<String, dynamic>> financeData = await getFinanceData();

    int currentKas = financeData[0]['kas'];
    int currentLaba = financeData[0]['laba'];

    int updatedKas = currentKas + totalCost.toInt();
    double updatedLaba = currentLaba + profit;

    await SQLHelper.updateKas(1, updatedKas);
    await SQLHelper.updateLaba(1, updatedLaba);
  }

  Future<void> _updateStock(int itemId, int quantitySold) async {
    await SQLHelper.updateStock(itemId, quantitySold);
  }

  Future<bool> _checkStockAvailability(
      int itemId, int requestedQuantity) async {
    int currentStock =
        _journals.firstWhere((journal) => journal['id'] == itemId)['stock'];

    if (requestedQuantity > currentStock) {
      return false;
    }
    return true;
  }

  void _showStockUnavailableWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Stock Unavailable", style: GoogleFonts.montserrat()),
          content: Text(
            "The requested quantity exceeds available stock.",
            style: GoogleFonts.montserrat(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK", style: GoogleFonts.montserrat()),
            ),
          ],
        );
      },
    );
  }
}
