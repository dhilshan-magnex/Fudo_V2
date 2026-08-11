import 'dart:async';
import 'package:flutter/material.dart';
import '../database/sqlite_class.dart';
import '../widgets/exit_button.dart';
import '../widgets/home_action_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.userName});

  final String userName;

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
    _clientInfoFuture = SQLiteClass.getClientInfo();
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
      appBar: AppBar(
        title: const Text('FUDO V2'),
        actions: const [
          ExitButton(),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final useTwoColumns = isLandscape && constraints.maxWidth >= 640;
            final contentPadding = EdgeInsets.all(useTwoColumns ? 20 : 16);

            return SingleChildScrollView(
              padding: contentPadding,
              child: useTwoColumns ? _landscapeLayout() : _portraitLayout(),
            );
          },
        ),
      ),
    );
  }

  Widget _portraitLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _clientDetails()),
        _actionButtons(wrapButtons: false),
      ],
    );
  }

  Widget _landscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _clientDetails()),
        const SizedBox(width: 24),
        SizedBox(
          width: 336,
          child: Align(
            alignment: Alignment.topRight,
            child: _actionButtons(wrapButtons: true),
          ),
        ),
      ],
    );
  }

  Widget _clientDetails() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _clientInfoFuture,
      builder: (context, snapshot) {
        final clientInfo = snapshot.data;
        final clientName = clientInfo?['Client_Name']?.toString() ?? '';
        final clientId = clientInfo?['Client_ID']?.toString() ?? '';
        final status = clientInfo?['Status']?.toString() ?? '';
        final licenseValid = clientInfo?['License_valid']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName.isEmpty ? 'Client Name' : clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    clientId.isEmpty ? 'Client ID: -' : 'Client ID: $clientId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE3E8EF),
                ),
              ),
              _infoRow(
                icon: Icons.person_outline,
                label: 'Log User',
                value: widget.userName,
              ),
              const SizedBox(height: 9),
              _infoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Current Date',
                value: _formatDate(_now),
              ),
              const SizedBox(height: 9),
              _infoRow(
                icon: Icons.access_time,
                label: 'Time',
                value: _formatTime(_now),
              ),
              const SizedBox(height: 9),
              _statusChip(label: 'Status', value: status),
              const SizedBox(height: 9),
              _statusChip(label: 'License valid', value: licenseValid),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip({required String label, required String value}) {
    final normalized = value.trim().toLowerCase();
    final isPositive = normalized == 'active' ||
        normalized == 'valid' ||
        normalized == 'yes' ||
        normalized == 'true' ||
        normalized == '1';
    final statusColor =
        isPositive ? const Color(0xFF16733A) : const Color(0xFF667085);
    final displayValue = value.trim().isEmpty ? 'Not set' : value.trim();

    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  displayValue,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButtons({required bool wrapButtons}) {
    final buttons = [
      HomeActionButton(icon: Icons.receipt_long, label: 'Billing', onTap: () {}),
      HomeActionButton(icon: Icons.dashboard, label: 'Dashboard', onTap: () {}),
      HomeActionButton(icon: Icons.bar_chart, label: 'Reports', onTap: () {}),
      HomeActionButton(
        icon: Icons.point_of_sale,
        label: 'POS Setting',
        onTap: () {},
      ),
      HomeActionButton(
        icon: Icons.switch_account,
        label: 'Change User',
        onTap: () {},
      ),
      HomeActionButton(
        icon: Icons.lock_reset,
        label: 'Change Password',
        onTap: () {},
      ),
      HomeActionButton(
        icon: Icons.attach_money,
        label: 'Cash Out',
        onTap: () {},
      ),
    ];

    if (wrapButtons) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: buttons,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: buttons,
    );
  }
}
