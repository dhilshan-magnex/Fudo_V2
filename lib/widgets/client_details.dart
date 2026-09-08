import 'package:flutter/material.dart';
import '../utils/global_colors.dart';
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
            padding: EdgeInsets.symmetric(vertical: 12),

            child: Divider(
              height: 1,
              thickness: 1,
              color: GlobalColors.divider,
            ),
          ),

          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Client ID',
                  value: clientId,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Log User',
                  value: userName,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: _formatDate(currentDateTime),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoRow(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: _formatTime(currentDateTime),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: StatusChip(label: 'Status', value: status),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatusChip(
                  label: 'License valid',
                  value: licenseValid,
                ),
              ),
            ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: GlobalColors.secondaryText),

        const SizedBox(width: 7),

        Text(label, style: GlobalColors.infoLabelTextStyle),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,

            textAlign: TextAlign.right,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: GlobalColors.infoValueTextStyle,
          ),
        ),
      ],
    );
  }
}
