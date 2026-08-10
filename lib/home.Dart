import 'dart:async';

import 'package:flutter/material.dart';

import 'database/db_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<Map<String, dynamic>?> _clientInfoFuture;
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _clientInfoFuture = DBManager.getClientInfo();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return '$day/$month/$year';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FUDO V2')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: _clientInfoFuture,
                    builder: (context, snapshot) {
                      final clientInfo = snapshot.data;
                      final clientName =
                          clientInfo?['Client_Name']?.toString() ?? '';
                      final clientId =
                          clientInfo?['Client_ID']?.toString() ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Client Name: $clientName',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Log User: ',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Client ID: $clientId',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Current Date: ${_formatDate(_now)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Time: ${_formatTime(_now)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Status: ',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'License valid: ',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
                ),

                // Right side: action buttons stacked vertically
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _actionButton(
                      icon: Icons.receipt_long,
                      label: 'Billing',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.dashboard,
                      label: 'Dashboard',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.bar_chart,
                      label: 'Reports',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.point_of_sale,
                      label: 'POS Setting',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.switch_account,
                      label: 'Change User',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.lock_reset,
                      label: 'Change Password',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.attach_money,
                      label: 'Cash Out',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.exit_to_app,
                      label: 'Exit',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 160,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
