import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:inti_apps/database/sql_helper.dart';
import 'package:inti_apps/pages/insert_data.dart';
import 'package:calendar_appbar/calendar_appbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? selectedDate;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _finance = [];
  TextEditingController _kasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _fetchFinance();
  }

  Future<void> _fetchTransactions() async {
    final transactions = await getTransaction();
    setState(() {
      _transactions = transactions;
    });
  }

  Future<void> _fetchFinance() async {
    final finance = await getFinanceData();
    setState(() {
      _finance = finance;
    });
  }

  Future<String> getItemName(int itemId) async {
    final item = await SQLHelper.getItem(itemId);
    return item.isNotEmpty ? item[0]['name'] : 'Barang Tidak Ditemukan';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }

  void _showTransactionPopup(List<Map<String, dynamic>> transactions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text("Transactions on ${_formatDate(selectedDate.toString())}"),
          content: SingleChildScrollView(
            child: Column(
              children: transactions.map((transaction) {
                return ListTile(
                  title: FutureBuilder<String>(
                    future: getItemName(transaction['item_id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return LoadingIndicator();
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else {
                        String itemName = snapshot.data ?? 'Item not found';
                        return Text("$itemName");
                      }
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Jumlah: ${transaction['quantity']}"),
                      Text(
                        "${_formatDate(transaction['transaction_date'])}",
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CalendarAppBar(
              accent: Colors.amber,
              backButton: false,
              locale: "id",
              onDateChanged: (value) {
                setState(() {
                  selectedDate = DateTime(value.year, value.month, value.day);
                  _fetchTransactionsByDate();
                });
              },
              firstDate: DateTime.now().subtract(Duration(days: 140)),
              lastDate: DateTime.now(),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildKasSection(),
          ),
          SliverToBoxAdapter(
            child: _buildLabaSection(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Riwayat Transaksi',
                style: GoogleFonts.montserrat(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final transaction = _transactions[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      title: FutureBuilder<String>(
                        future: getItemName(transaction['item_id']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return LoadingIndicator();
                          } else if (snapshot.hasError) {
                            return Text("Error: ${snapshot.error}");
                          } else {
                            String itemName = snapshot.data ?? 'Item not found';
                            return Text("$itemName");
                          }
                        },
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Jumlah: ${transaction['quantity']}"),
                          Text(
                            "${_formatDate(transaction['transaction_date'])}",
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: _transactions.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => InsertNew()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.amber,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  bool _reduceButtonEnabled = true;
  Widget _buildKasSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Row(
          children: [
            Container(
              child: Icon(Icons.attach_money_outlined, color: Colors.amber),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kas",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future:
                        Future.value(_finance.isNotEmpty ? _finance[0] : {}),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return LoadingIndicator();
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else {
                        final financeData = snapshot.data ?? {};
                        int kas = financeData['kas'] ?? 0;

                        return Text(
                          "Rp$kas",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    _showAddKasDialog();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: _reduceButtonEnabled
                      ? () {
                          _showReduceKasDialog();
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReduceKasDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Kurangi Kas", style: GoogleFonts.montserrat()),
          content: TextField(
            controller: _kasController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Masukkan Jumlah"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel", style: GoogleFonts.montserrat()),
            ),
            TextButton(
              onPressed: () {
                int amountToReduce = int.tryParse(_kasController.text) ?? 0;
                _reduceKas(amountToReduce);
                Navigator.of(context).pop();
              },
              child: Text("Reduce", style: GoogleFonts.montserrat()),
            ),
          ],
        );
      },
    );
  }

  void _reduceKas(int amountToReduce) async {
    setState(() {
      _reduceButtonEnabled = false;
    });

    int currentKas = _finance.isNotEmpty ? _finance[0]['kas'] : 0;
    int updatedKas = currentKas - amountToReduce;
    await SQLHelper.updateKas(1, updatedKas); // Assuming finance entry has ID 1

    _fetchFinance();

    setState(() {
      _reduceButtonEnabled = true;
    });

    _kasController.clear(); // Clear the text field
  }

  Widget _buildLabaSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Row(
          children: [
            Container(
              child: Icon(Icons.attach_money_outlined, color: Colors.amber),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Laba",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future:
                        Future.value(_finance.isNotEmpty ? _finance[0] : {}),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return LoadingIndicator();
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else {
                        final financeData = snapshot.data ?? {};
                        int laba = financeData['laba'] ?? 0;

                        return Text(
                          "Rp$laba",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddKasDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Tambah Kas", style: GoogleFonts.montserrat()),
          content: TextField(
            controller: _kasController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Masukkan Jumlah"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel", style: GoogleFonts.montserrat()),
            ),
            TextButton(
              onPressed: () {
                int amountToAdd = int.tryParse(_kasController.text) ?? 0;
                _updateKas(amountToAdd);
                Navigator.of(context).pop();
              },
              child: Text("Add", style: GoogleFonts.montserrat()),
            ),
          ],
        );
      },
    );
  }

  void _updateKas(int amountToAdd) {
    int currentKas = _finance.isNotEmpty ? _finance[0]['kas'] : 0;
    int updatedKas = currentKas + amountToAdd;
    SQLHelper.updateKas(1, updatedKas); // Assuming finance entry has ID 1
    _fetchFinance();
    _kasController.clear(); // Clear the text field
  }

  Future<void> _fetchTransactionsByDate() async {
    // Filter transactions based on selectedDate
    final transactionsByDate = _transactions.where((transaction) {
      DateTime transactionDate =
          DateTime.parse(transaction['transaction_date']);
      return transactionDate.year == selectedDate!.year &&
          transactionDate.month == selectedDate!.month &&
          transactionDate.day == selectedDate!.day;
    }).toList();

    // Show the pop-up with filtered transactions
    _showTransactionPopup(transactionsByDate);
  }
}

class LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator();
  }
}
