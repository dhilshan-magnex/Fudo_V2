import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/session/session_provider.dart';
import 'core/session/running_orders_store.dart';
import 'features/orders/data/order_database.dart';
import 'features/orders/data/order_repository.dart';
import 'features/orders/state/order_provider.dart';
import 'pages/tables/state/table_layout_provider.dart';
import 'pages/login_page.dart';
import 'data/api/api_http_client.dart';

void main() {
  // Use sqflite_common_ffi only for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(OrderRepository(OrderDatabase())),
        ),
        ChangeNotifierProvider(create: (_) => RunningOrdersStore()),
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
      home: const LoginPage(),
    );
  }
}
