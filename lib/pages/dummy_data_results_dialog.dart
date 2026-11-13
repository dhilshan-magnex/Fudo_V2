import 'package:flutter/material.dart';

import '../core/theme/global_colors.dart';
import '../data/dummy_data.dart';

class DummyDataResultsDialog extends StatelessWidget {
  const DummyDataResultsDialog({
    required this.results,
    required this.failed,
    required this.destination,
    super.key,
  });

  final List<DummyTableResult> results;
  final bool failed;
  final String destination;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: EdgeInsets.all(compact ? 20 : 24),
          decoration: BoxDecoration(
            color: GlobalColors.homeHeaderBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        failed ? Icons.info_outline : Icons.task_alt,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        failed ? 'Dummy data incomplete' : 'Dummy data results',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Counter information saved in Sys.db.\nDestination: $destination',
                  style: const TextStyle(
                    color: GlobalColors.homeHeaderLabel,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                for (final result in results) _resultCard(result),
                if (failed) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: GlobalColors.homeStatusBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Setup could not finish. Close this message and select Continue to retry.',
                      style: TextStyle(
                        color: GlobalColors.homeStatusForeground,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    failed ? Icons.close_rounded : Icons.arrow_forward_rounded,
                  ),
                  label: Text(failed ? 'Close' : 'Continue setup'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: GlobalColors.buttonBackground,
                    minimumSize: const Size.fromHeight(56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultCard(DummyTableResult result) {
    final complete = result.status == 'Complete';
    final skipped = result.status.startsWith('Skipped');
    final pending = result.status == 'Not attempted';
    final color = complete
        ? GlobalColors.homeHeaderLabel
        : GlobalColors.homeStatusBackground;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            complete
                ? Icons.check_circle_outline
                : skipped
                ? Icons.skip_next_outlined
                : pending
                ? Icons.schedule
                : Icons.error_outline,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.table,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${result.inserted} inserted · ${result.existing} already present',
                  style: const TextStyle(
                    color: GlobalColors.homeHeaderLabel,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  result.status,
                  style: TextStyle(color: color, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
