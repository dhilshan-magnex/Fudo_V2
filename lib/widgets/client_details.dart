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
    this.mobileHeader = false,
    this.tabletHeader = false,
    this.tabletStatusAtBottom = false,
    this.desktopHeader = false,
  });

  final String clientName;
  final String clientId;
  final String userName;
  final String status;
  final String licenseValid;
  final DateTime currentDateTime;
  final bool mobileHeader;
  final bool tabletHeader;
  final bool tabletStatusAtBottom;
  final bool desktopHeader;

  bool get _showClientName => clientName.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (desktopHeader) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showClientName)
            Text(
              clientName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GlobalColors.homeHeaderLabel,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (_showClientName)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Divider(height: 1, color: Color(0x33AFC4C4)),
            ),
          _headerDetails(rowGap: 24),
          const Spacer(),
          _headerStatuses(),
        ],
      );
    }

    if (tabletHeader) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showClientName)
            Text(
              clientName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GlobalColors.homeHeaderLabel,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (_showClientName) const SizedBox(height: 26),
          _headerDetails(rowGap: 16),
          if (tabletStatusAtBottom)
            const Spacer()
          else
            const SizedBox(height: 24),
          _headerStatuses(),
        ],
      );
    }

    if (mobileHeader) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showClientName)
                Text(
                  clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GlobalColors.homeHeaderLabel,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (_showClientName) const SizedBox(height: 18),
              _headerDetails(rowGap: 12),
              const SizedBox(height: 16),
              _headerStatuses(),
            ],
          ),
        ),
      );
    }

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

          // Group related desktop details into left and right columns so the
          // user, time, and license details sit on the right side.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: _formatDate(currentDateTime),
                        ),
                        const SizedBox(height: 6),
                        StatusChip(label: 'Status', value: status),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClientDetailLabel(
                          icon: Icons.person_outline,
                          label: 'Log User',
                          value: userName,
                        ),
                        const SizedBox(height: 6),
                        ClientDetailLabel(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: _formatTime(currentDateTime),
                        ),
                        const SizedBox(height: 6),
                        StatusChip(label: 'License valid', value: licenseValid),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerDetails({required double rowGap}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _mobileDetail('CLIENT ID', clientId),
              SizedBox(height: rowGap),
              _mobileDetail('DATE', _formatDate(currentDateTime)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _mobileDetail('USER', userName, alignRight: true),
              SizedBox(height: rowGap),
              _mobileDetail(
                'TIME',
                _formatTime(currentDateTime),
                alignRight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerStatuses() {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _mobileStatus('Status', status),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _mobileStatus('License', licenseValid),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileDetail(String label, String value, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GlobalColors.homeHeaderLabel,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '-' : value,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _mobileStatus(String label, String value) {
    final displayValue = value.trim().isEmpty ? 'Not set' : value.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: GlobalColors.homeStatusBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.circle,
            size: 8,
            color: GlobalColors.homeStatusForeground,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $displayValue',
            style: const TextStyle(
              color: GlobalColors.homeStatusForeground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
