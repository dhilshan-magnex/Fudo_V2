import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database/db_manager.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for Windows/Linux/macOS
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final db = await DBManager.getDatabase(AppDatabase.fudo);
  final sysDb = await DBManager.getDatabase(AppDatabase.sys);

  print("Database Connected!");
  print("Database Path: ${db.path}");
  print("Sys Database Path: ${sysDb.path}");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}