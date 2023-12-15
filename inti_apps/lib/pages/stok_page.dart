import 'package:flutter/material.dart';

class Item {
  final String name;
  final int stock;
  final double price;

  Item(this.name, this.stock, this.price);
}

class StockPage extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Page'),
        backgroundColor: Colors.amber,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ItemListPage()),
            );
          },
          child: Text('Go to Item List Page'),
        ),
      ),
    );
  }
}

class ItemListPage extends StatelessWidget {
  final List<Item> items = [
    Item('Product A', 10, 20.0),
    Item('Product B', 5, 15.0),
    Item('Product C', 8, 25.0),
    // Add more items as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item List'),
        backgroundColor: Colors.amber,
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(items[index].name),
            subtitle: Text(
                'Stock: ${items[index].stock}, Price: \$${items[index].price.toStringAsFixed(2)}'),
            // You can add more customization to ListTile as needed
          );
        },
      ),
    );
  }
}
