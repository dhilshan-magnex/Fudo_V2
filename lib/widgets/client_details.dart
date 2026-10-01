import 'package:flutter/material.dart';
import '../utils/global_colors.dart';
import 'label.dart';
import 'status_chip.dart';

class ClientDetails extends StatelessWidget {
  const ClientDetails({
    super.key,
    required this.clientName,
    required this.clientId,
    required this.userName,
    required this.status,
    required this.licenseValid,
    required this.currentDateTime,
  });

  final String clientName;
  final String clientId;
  final String userName;
  final String status;
  final String licenseValid;
  final DateTime currentDateTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Center(
            child: Text(
              clientName.isEmpty ? 'Client Name' : clientName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GlobalColors.clientTitleTextStyle,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),

            child: Divider(
              height: 1,
              thickness: 1,
              color: GlobalColors.divider,
            ),
          ),

          // Keep the desktop information rows compact while preserving a
          // consistent left-label/right-value alignment on every screen size.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClientDetailLabel(
                    icon: Icons.badge_outlined,
                    label: 'Client ID',
                    value: clientId,
                  ),
                  const SizedBox(height: 6),
                  ClientDetailLabel(
                    icon: Icons.person_outline,
                    label: 'Log User',
                    value: userName,
                  ),
                  const SizedBox(height: 6),
                  ClientDetailLabel(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: _formatDate(currentDateTime),
                  ),
                  const SizedBox(height: 6),
                  ClientDetailLabel(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: _formatTime(currentDateTime),
                  ),
                  const SizedBox(height: 6),
                  StatusChip(label: 'Status', value: status),
                  const SizedBox(height: 6),
                  StatusChip(label: 'License valid', value: licenseValid),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
}
