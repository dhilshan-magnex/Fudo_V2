import 'package:flutter/material.dart';
import 'database/db_manager.dart'; // match your actual file name/path
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
