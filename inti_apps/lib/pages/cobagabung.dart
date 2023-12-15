import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inti_apps/database/sql_helper.dart';
import 'package:inti_apps/pages/addStock_page.dart';

class Item {
  final String name;
  final int stock;
  final double price;

  Item(this.name, this.stock, this.price);
}

class ChartData {
  final String label;
  final double value;

  ChartData({required this.label, required this.value});
}

class CombinedPage extends StatefulWidget {
  @override
  _CombinedPageState createState() => _CombinedPageState();
}

class _CombinedPageState extends State<CombinedPage> {
  List<Map<String, dynamic>> _journals = [];

  bool _isLoading = true;

  void _refreshJournals() async {
    final data = await getItems();
    setState(() {
      _journals = data;
      _isLoading = false;
    });
  }

  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _refreshJournals();
    });
  }

  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Berhasil dihapus'),
    ));
    _refreshJournals();
  }

  int selectedPage = 0; // 0 for stock, 1 for statistics

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: selectedPage == 0
            ? Text('Stock', style: GoogleFonts.montserrat())
            : selectedPage == 1
                ? Text('Laporan', style: GoogleFonts.montserrat())
                : Text('Unknown Page', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.amber,
      ),
      body: selectedPage == 0
          ? buildStockView()
          : selectedPage == 1
              ? buildStatisticView()
              : buildUnknownPageView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedPage,
        onTap: (index) {
          setState(() {
            selectedPage = index;
            _refreshJournals();
          });
        },
        selectedItemColor: Colors.amber, // Set the selected item color to amber
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Barang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }

  Widget buildStockView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _journals.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_journals[index]['name'],
                    style: GoogleFonts.montserrat()),
                subtitle: Text(
                  'Stock: ${_journals[index]['stock']}, Harga Beli: Rp${_journals[index]['buy_cost'].toStringAsFixed(2)}, Harga Jual: Rp${_journals[index]['sell_cost'].toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(),
                ),
                trailing: SizedBox(
                  width: 50,
                  child: Row(children: [
                    IconButton(
                        onPressed: () => _deleteItem(_journals[index]['id']),
                        icon: Icon(Icons.delete))
                  ]),
                ),
                onTap: () {
                  // Show the bottom sheet when a list item is tapped
                  _showStockDetailsBottomSheet(context, _journals[index]);
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddStockForm(),
                    ),
                  );
                },
                child: Icon(Icons.add),
                backgroundColor:
                    Colors.amber, // Set the background color to amber
              ),
              FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddStockForm(edit: true),
                    ),
                  );
                },
                child: Icon(Icons.edit),
                backgroundColor:
                    Colors.amber, // Set the background color to amber
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStockDetailsBottomSheet(
      BuildContext context, Map<String, dynamic> stockData) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Detail Barang', style: GoogleFonts.montserrat()),
                SizedBox(height: 8),
                ListTile(
                  title: Text('Nama', style: GoogleFonts.montserrat()),
                  subtitle:
                      Text(stockData['name'], style: GoogleFonts.montserrat()),
                ),
                ListTile(
                  title: Text('Stock', style: GoogleFonts.montserrat()),
                  subtitle: Text(stockData['stock'].toString(),
                      style: GoogleFonts.montserrat()),
                ),
                ListTile(
                  title: Text('Harga Beli', style: GoogleFonts.montserrat()),
                  subtitle: Text(
                      'Rp${stockData['buy_cost'].toStringAsFixed(2)}',
                      style: GoogleFonts.montserrat()),
                ),
                ListTile(
                  title: Text('Harga Jual', style: GoogleFonts.montserrat()),
                  subtitle: Text(
                      'Rp${stockData['sell_cost'].toStringAsFixed(2)}',
                      style: GoogleFonts.montserrat()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildStatisticView() {
    return FutureBuilder(
      future: SQLHelper.getSales(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else {
          List<Map<String, dynamic>> salesData =
              snapshot.data as List<Map<String, dynamic>>;

          // Generate report for highest sales
          List<String> highestSalesReport =
              generateHighestSalesReport(salesData);

          // Generate report for items with stock less than 3
          List<String> lowStockItemsReport =
              generateLowStockItemsReport(_journals);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Penjualan Tertinggi:',
                  style: GoogleFonts.montserrat(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                for (var item in highestSalesReport)
                  Card(
                    elevation: 4.0,
                    margin: EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.all(16.0),
                      child: Text(item, style: GoogleFonts.montserrat()),
                    ),
                  ),
                SizedBox(height: 16),
                Text(
                  'Barang dengan stock kurang dari 10:',
                  style: GoogleFonts.montserrat(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                for (var item in lowStockItemsReport)
                  Card(
                    elevation: 4.0,
                    margin: EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.all(16.0),
                      child: Text(item, style: GoogleFonts.montserrat()),
                    ),
                  ),
              ],
            ),
          );
        }
      },
    );
  }

  void printSalesToConsole() async {
    await SQLHelper.printSalesToConsole();
  }

  List<String> generateHighestSalesReport(
      List<Map<String, dynamic>> salesData) {
    List<Map<String, dynamic>> sortedSalesData = List.from(salesData);
    sortedSalesData.sort((a, b) => b['sold'].compareTo(a['sold']));

    List<String> report = [];
    int itemsToShow = sortedSalesData.length > 5 ? 5 : sortedSalesData.length;

    for (int i = 0; i < itemsToShow; i++) {
      int itemId = sortedSalesData[i]['item_id'];
      List<Map<String, dynamic>> itemData =
          _journals.where((item) => item['id'] == itemId).toList();

      if (itemData.isNotEmpty) {
        report.add(
            '${i + 1}. ${itemData[0]['name']} - ${sortedSalesData[i]['sold']} pcs');
      } else {
        report
            .add('${i + 1}. Unknown Item - ${sortedSalesData[i]['sold']} pcs');
      }
    }

    return report;
  }

  List<String> generateLowStockItemsReport(
      List<Map<String, dynamic>> journals) {
    List<Map<String, dynamic>> lowStockItems =
        journals.where((item) => item['stock'] < 10).toList();
    List<String> report = [];

    for (int i = 0; i < lowStockItems.length; i++) {
      report.add(
          '${i + 1}. ${lowStockItems[i]['name']} - Stock: ${lowStockItems[i]['stock']}');
    }

    return report;
  }

  List<BarChartGroupData> getBarGroups(List<ChartData> data) {
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < data.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              y: data[i].value,
              width: 16,
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return barGroups;
  }

  Widget buildUnknownPageView() {
    return Center(
      child: Text("Unknown Page", style: GoogleFonts.montserrat()),
    );
  }
}

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
      primarySwatch: Colors.amber,
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.amber, // Change the button color to amber
        textTheme: ButtonTextTheme.primary,
      ),
    ),
    home: CombinedPage(),
  ));
}
