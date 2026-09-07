import 'dart:async';
import 'package:flutter/material.dart';
import '../services/client_service.dart';
import '../widgets/client_details.dart';
import '../widgets/exit_button.dart';
import '../widgets/button.dart';
import '../widgets/layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _clientService = ClientService();

  final _homeButtons = [
    HomeActionButton(
      icon: Icons.receipt_long,
      label: 'Billing',
      onTap: _emptyAction,
    ),
    HomeActionButton(
      icon: Icons.dashboard,
      label: 'Dashboard',
      onTap: _emptyAction,
    ),
    HomeActionButton(
      icon: Icons.bar_chart,
      label: 'Reports',
      onTap: _emptyAction,
    ),
    HomeActionButton(
      icon: Icons.point_of_sale,
      label: 'POS Setting',
      onTap: _emptyAction,
    ),
    HomeActionButton(
      icon: Icons.switch_account,
      label: 'Change User',
      onTap: _emptyAction,
    ),
    HomeActionButton(
      icon: Icons.lock_reset,
      label: 'Change Password',
      onTap: _emptyAction,
    ),
    HomeActionButton(
      icon: Icons.attach_money,
      label: 'Cash Out',
      onTap: _emptyAction,
    ),
  ];

  static void _emptyAction() {}

  late final Future<Map<String, dynamic>?>
      _clientInfoFuture;

  late DateTime _now;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _clientInfoFuture =
        _clientService.getClientInfo();

    _now = DateTime.now();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _now = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FUDO V2'),
        actions: const [
          ExitButton(),
        ],
      ),

      body: SafeArea(
        child: HomeLayout(
          primaryContent: ClientDetails(
            clientInfoFuture:
                _clientInfoFuture,
            currentDateTime: _now,
          ),

          portraitSideContent:
              HomeActionPanel(
            wrapButtons: true,
            buttons: _homeButtons,
          ),

          landscapeSideContent:
              HomeActionPanel(
            wrapButtons: true,
            buttons: _homeButtons,
          ),
        ),
      ),
    );
  }
}