import 'package:flutter/material.dart';

Future<void> showSetupSyncResults(
  BuildContext context, {
  required String? clientType,
  required List<String> results,
  String? error,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    title: Text(error == null ? 'Setup data results' : 'Setup data failed'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client type: ${clientType ?? "Not available"}'),
            const SizedBox(height: 16),
            for (final result in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(result),
              ),
            if (error != null)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(error == null ? 'Continue' : 'Close'),
      ),
    ],
  ),
);
