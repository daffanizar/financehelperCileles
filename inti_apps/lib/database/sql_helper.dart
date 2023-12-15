import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SQLHelper {
  static Future<void> createTableItems(sql.Database database) async {
    await database.execute('''
      CREATE TABLE items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      stock INTEGER NOT NULL,
      buy_cost REAL NOT NULL,
      sell_cost REAL NOT NULL
  );
''');
  }

  static Future<void> createTableTransaction(sql.Database database) async {
    await database.execute("""
      CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_id INTEGER,
      quantity INTEGER NOT NULL,
      transaction_date TEXT NOT NULL,
      FOREIGN KEY (item_id) REFERENCES items(id) 
      );
    """);
  }

  static Future<void> createTableFinance(sql.Database database) async {
    await database.execute("""
    CREATE TABLE finance (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      kas INTEGER,
      laba INTEGER NOT NULL
    );
  """).catchError((error) {
      print("Error creating finance table: $error");
    });
  }

  static Future<void> createTableSales(sql.Database database) async {
    await database.execute("""
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER,
        sold INTEGER NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id)
      );
    """);
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'dbdb_Inti.db1',
      version: 2,
      onCreate: (sql.Database database, int version) async {
        await createTableItems(database);
        await createTableTransaction(database);
        await createTableFinance(database);
        await createTableSales(database);
      },
    );
  }

  static Future<void> printSalesToConsole() async {
    final db = await SQLHelper.db();
    List<Map<String, dynamic>> sales = await db.query('sales');

    print('Sales data in the database:');
    for (var sale in sales) {
      print('ID: ${sale['id']}');
      print('Item ID: ${sale['item_id']}');
      print('Sold Quantity: ${sale['sold']}');
      print('-------------------');
    }
  }

  static Future<void> updateSold(int itemId, int quantitySold) async {
    final db = await SQLHelper.db();

    // Fetch the current sold value of the item in the sales table
    List<Map<String, dynamic>> result = await db.query(
      'sales',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );

    if (result.isNotEmpty) {
      int currentSold = result.first['sold'];

      // Calculate the updated sold value after the transaction
      int updatedSold = currentSold + quantitySold;

      // Update the sold value in the sales table
      await db.update(
        'sales',
        {'sold': updatedSold},
        where: 'item_id = ?',
        whereArgs: [itemId],
      );
    } else {
      await createSale(itemId, quantitySold);
    }
  }

  static Future<int> createSale(int itemId, int quantitySold) async {
    final db = await SQLHelper.db();

    final data = {
      'item_id': itemId,
      'sold': quantitySold,
    };

    final id = await db.insert('sales', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<int> updateSale(int id, int quantitySold) async {
    final db = await SQLHelper.db();

    final data = {
      'sold': quantitySold,
    };

    final result =
        await db.update('sales', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<int> createItem(
      String name, int stock, double buy_cost, double sell_cost) async {
    final db = await SQLHelper.db();

    final data = {
      'name': name,
      'stock': stock,
      'buy_cost': buy_cost,
      'sell_cost': sell_cost
    };
    final id = await db.insert('items', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<int> createTransaction(
      int item_id, int quantity, String transaction_date) async {
    final db = await SQLHelper.db();
    final data = {
      'item_id': item_id,
      'quantity': quantity,
      'transaction_date': transaction_date,
    };
    final id = await db.insert('transactions', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<int> addFinanceData(int kas, int laba) async {
    final db = await SQLHelper.db();

    final data = {
      'kas': kas,
      'laba': laba,
    };

    final id = await db.insert('finance', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<int> updateFinanceData(int id, int kas, int laba) async {
    final db = await SQLHelper.db();

    final data = {
      'kas': kas,
      'laba': laba,
    };

    final result =
        await db.update('finance', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<int> updateKas(int id, int kas) async {
    final db = await SQLHelper.db();

    final data = {
      'kas': kas,
    };

    final result =
        await db.update('finance', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<bool> isFinanceTableEmpty() async {
    final db = await SQLHelper.db();
    List<Map<String, dynamic>> result = await db.query('finance', limit: 1);
    return result.isEmpty;
  }

  static Future<int> updateLaba(int id, double laba) async {
    final db = await SQLHelper.db();

    final data = {
      'laba': laba,
    };

    final result =
        await db.update('finance', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await SQLHelper.db();
    return db.query('items', where: "id = ?", whereArgs: [id], limit: 1);
  }

  static Future<List<Map<String, dynamic>>> getSales() async {
    final db = await SQLHelper.db();
    return db.query('sales', orderBy: "id");
  }

  static Future<void> deleteItem(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete('items', where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  static Future<int> UpdateItem(String currentName, String name, int stock,
      double buy_cost, double sell_cost) async {
    final db = await SQLHelper.db();

    final data = {
      'name': name,
      'stock': stock,
      'buy_cost': buy_cost,
      'sell_cost': sell_cost
    };

    final result = await db
        .update('items', data, where: "name = ?", whereArgs: [currentName]);
    return result;
  }

  static Future<int> UpdateTransaction(
    int id,
    int quantity,
  ) async {
    final db = await SQLHelper.db();

    final data = {
      'quantity': quantity,
    };

    final result =
        await db.update('items', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  Future<bool> isTableExists(String tableName) async {
    final db = await SQLHelper.db();
    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );

    return result.isNotEmpty;
  }

  static Future<void> updateStock(int itemId, int quantitySold) async {
    final db = await SQLHelper.db();

    // Fetch the current stock of the item
    List<Map<String, dynamic>> result = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [itemId],
    );

    if (result.isNotEmpty) {
      int currentStock = result.first['stock'];

      // Calculate the updated stock after the transaction
      int updatedStock = currentStock - quantitySold;
      if (updatedStock < 0) {
        // Optional: Handle negative stock (if allowed in your business logic)
        updatedStock = 0;
      }

      // Update the stock in the items table
      await db.update(
        'items',
        {'stock': updatedStock},
        where: 'id = ?',
        whereArgs: [itemId],
      );
    }
    await updateSold(itemId, quantitySold);
  }
}

Future<List<Map<String, dynamic>>> getItems() async {
  final db = await SQLHelper.db();
  return db.query('items', orderBy: "id");
}

Future<List<Map<String, dynamic>>> getTransaction() async {
  final db = await SQLHelper.db();
  return db.query('transactions', orderBy: "transaction_date DESC");
}

Future<List<Map<String, dynamic>>> getFinanceData() async {
  final db = await SQLHelper.db();

  // Check if finance table is empty
  if (await SQLHelper.isFinanceTableEmpty()) {
    // If empty, add default finance data
    await SQLHelper.addFinanceData(0, 0);
  }

  // Query finance data from the database
  try {
    final financeData = await db.query('finance', orderBy: "id");
    return financeData;
  } catch (e) {
    print("Error fetching finance data: $e");
    return []; // Return an empty list in case of an error
  }
}

Future<List<Map<String, dynamic>>> getTransactionsByDate(
    DateTime? selectedDate) async {
  if (selectedDate == null) {
    // Handle the case when selectedDate is null
    return [];
  }

  final db =
      await SQLHelper.db(); // Ensure that you await the database initialization
  final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

  final List<Map<String, dynamic>> result = await db.query(
    'transactions',
    where: 'transaction_date = ?',
    whereArgs: [formattedDate],
  );

// Use the result as needed

  return result;
}
