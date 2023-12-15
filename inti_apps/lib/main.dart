import 'package:flutter/material.dart';
import 'package:calendar_appbar/calendar_appbar.dart';
import 'package:inti_apps/pages/home_page.dart';
import 'package:inti_apps/pages/main_page.dart';
import 'package:inti_apps/pages/splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Splash());
  }
}
