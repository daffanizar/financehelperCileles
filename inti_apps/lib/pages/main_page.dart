import 'package:calendar_appbar/calendar_appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import the Google Fonts package
import 'package:inti_apps/database/sql_helper.dart';
import 'package:inti_apps/pages/addStock_page.dart';
import 'package:inti_apps/pages/cobagabung.dart';
import 'package:inti_apps/pages/home_page.dart';
import 'package:inti_apps/pages/insert_data.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Widget> _children = [
    HomePage(),
    CombinedPage(),
    // StockPage(),
    AddStockForm(),
  ];
  int currentIndex = 0;

  void onTapTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[currentIndex],
      bottomNavigationBar: BottomAppBar(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(
            onPressed: () {
              onTapTapped(0);
            },
            icon: Icon(Icons.home),
          ),
          IconButton(
            onPressed: () {
              onTapTapped(1);
            },
            icon: Icon(Icons.collections_bookmark),
          ),
        ]),
      ),
    );
  }
}
