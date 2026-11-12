import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/session/session_provider.dart';
import 'functions/orders/data/order_database.dart';
import 'functions/orders/data/order_repository.dart';
import 'functions/orders/state/order_provider.dart';
import 'functions/orderdetails/order_details.dart';
import 'pages/tables/logic/table_layout_provider.dart';
import 'pages/initial_setup_page.dart';
import 'data/api/api_http_client.dart';
import 'data/database/db_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use sqflite_common_ffi only for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Copy the bundled system database to the app's database directory on the
  // first launch, before any screen needs client or counter configuration.
  await DBManager.getDatabase(AppDatabase.sys);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              OrderProvider(OrderRepository(OrderDatabase(), KotService())),
        ),
        ChangeNotifierProvider(create: (_) => TableLayoutProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ApiHttpClient.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      ApiHttpClient.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const StartupGate(),
    );
  }
}
