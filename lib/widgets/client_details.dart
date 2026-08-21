import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../session/session_provider.dart';
import 'status_chip.dart';

class ClientDetails extends StatelessWidget {
  const ClientDetails({
    super.key,
    required this.clientInfoFuture,
    required this.currentDateTime,
  });

  final Future<Map<String, dynamic>?> clientInfoFuture;
  final DateTime currentDateTime;

  @override
  Widget build(BuildContext context) {
    final session =
        context.watch<SessionProvider>();

    return FutureBuilder<Map<String, dynamic>?>(
      future: clientInfoFuture,

      builder: (context, snapshot) {
        final clientInfo = snapshot.data;

        final clientName =
            session.clientName ??
            clientInfo?['Client_Name']
                ?.toString() ??
            '';

        final clientId =
            session.clientId ??
            clientInfo?['Client_ID']
                ?.toString() ??
            '';

        final userName =
            session.userName ?? '';

        final status =
            clientInfo?['Status']
                ?.toString() ??
            '';

        final licenseValid =
            clientInfo?['License_valid']
                ?.toString() ??
            '';

        return Padding(
          padding:
              const EdgeInsets.only(right: 12),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    clientName.isEmpty
                        ? 'Client Name'
                        : clientName,

                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      color:
                          Color(0xFF111827),
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    clientId.isEmpty
                        ? 'Client ID: -'
                        : 'Client ID: $clientId',

                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      color:
                          Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 12,
                ),

                child: Divider(
                  height: 1,
                  thickness: 1,
                  color:
                      Color(0xFFE3E8EF),
                ),
              ),

              _InfoRow(
                icon:
                    Icons.person_outline,
                label: 'Log User',
                value: userName,
              ),

              const SizedBox(height: 9),

              _InfoRow(
                icon:
                    Icons.calendar_today_outlined,
                label: 'Current Date',
                value:
                    _formatDate(
                  currentDateTime,
                ),
              ),

              const SizedBox(height: 9),

              _InfoRow(
                icon: Icons.access_time,
                label: 'Time',
                value:
                    _formatTime(
                  currentDateTime,
                ),
              ),

              const SizedBox(height: 9),

              StatusChip(
                label: 'Status',
                value: status,
              ),

              const SizedBox(height: 9),

              StatusChip(
                label: 'License valid',
                value: licenseValid,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(
    DateTime dateTime,
  ) {
    final day =
        dateTime.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        dateTime.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        dateTime.year.toString();

    return '$day/$month/$year';
  }

  String _formatTime(
    DateTime dateTime,
  ) {
    final hour =
        dateTime.hour.toString().padLeft(
              2,
              '0',
            );

    final minute =
        dateTime.minute.toString().padLeft(
              2,
              '0',
            );

    final second =
        dateTime.second.toString().padLeft(
              2,
              '0',
            );

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
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color:
              const Color(0xFF6B7280),
        ),

        const SizedBox(width: 7),

        Text(
          label,
          style: const TextStyle(
            color:
                Color(0xFF6B7280),
            fontSize: 14,
            fontWeight:
                FontWeight.w500,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            value.isEmpty
                ? '-'
                : value,

            textAlign:
                TextAlign.right,

            maxLines: 1,

            overflow:
                TextOverflow.ellipsis,

            style: const TextStyle(
              color:
                  Color(0xFF111827),
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}