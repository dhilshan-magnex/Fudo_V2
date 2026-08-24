import 'dart:async';
import 'package:flutter/material.dart';
import '../services/client_service.dart';
import '../widgets/client_details.dart';
import '../widgets/exit_button.dart';
import '../widgets/home_action_panel.dart';
import '../widgets/layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _clientService = ClientService();

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
              const HomeActionPanel(
            wrapButtons: false,
          ),

          landscapeSideContent:
              const HomeActionPanel(
            wrapButtons: true,
          ),
        ),
      ),
    );
  }
}