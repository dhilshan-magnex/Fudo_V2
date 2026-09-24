import 'package:flutter/material.dart';
import '../database/api_route_registry.dart';
import '../function/app_functions.dart';
import '../widgets/button.dart';
import 'package:provider/provider.dart';
import '../session/session_provider.dart';
import '../services/access_control_service.dart';

class DataSyncDialog extends StatefulWidget {
  const DataSyncDialog({
    super.key,
  });

  @override
  State<DataSyncDialog> createState() =>
      _DataSyncDialogState();
}

class _DataSyncDialogState
    extends State<DataSyncDialog> {
  double? _progress = 0;

  bool _isSyncing = false;
  bool _syncComplete = false;

  String _message =
      'Do you want to synchronize categories now?';

  Future<void> _startSync() async {
  if (_isSyncing) {
    return;
  }

  final session = context.read<SessionProvider>();

  final groupCode = session.groupCode;

  if (groupCode == null || groupCode.trim().isEmpty) {
    if (!mounted) {
      return;
    }

    setState(() {
      _message =
          'User group information is unavailable.';
    });

    return;
  }

  final allowed =
      await AccessControlService.checkAccess(
    groupCode: groupCode,
    screenId: AppFunctions.dataSyncScreen,
    functionId: AppFunctions.dataSync,
  );

  if (!allowed) {
    if (!mounted) {
      return;
    }

    setState(() {
      _message =
          'You do not have permission to use Data Sync.';
    });

    return;
  }

  setState(() {
    _isSyncing = true;
    _syncComplete = false;
    _progress = null;
    _message = 'Starting data synchronization...';
  });

  try {
    final result = await ApiRouteRegistry.syncAll(
      clearExistingData: false,
      onProgress: (progress) {
        if (!mounted) {
          return;
        }

        setState(() {
          _progress =
              progress.completedCount == 0
                  ? null
                  : progress.value;

          _message = progress.isCompleted
              ? 'Data synchronization completed.'
              : 'Synchronizing ${progress.displayName}...';
        });
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSyncing = false;
      _syncComplete = true;
      _progress = 1;

      _message =
          'Data synchronization completed successfully.\n\n'
          'Categories: ${result.categories.total}\n'
          'Category Levels: ${result.catLevels.total}\n'
          'Credit Cards: ${result.creditCards.savedCount}\n'
          'Currencies: ${result.currencies.savedCount}\n'
          'Discounts: ${result.discounts.savedCount}\n'
          'Menu Items: ${result.menuItems.savedCount}\n'
          'More Sizes: ${result.moreSizes.savedCount}\n'
          'POS Master: ${result.posMast.savedCount}\n'
          'Sections: ${result.sections.savedCount}\n'
          'Shop Info: ${result.shopInfo.savedCount}\n'
          'Side Items: ${result.sideItems.savedCount}\n'
          'Table Layout: ${result.tableLayout.savedCount}\n'
          'Tax Groups: ${result.taxGroups.savedCount}\n'
          'Tax Master: ${result.taxMaster.savedCount}';
    });
  } catch (error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isSyncing = false;
      _syncComplete = false;
      _progress = 0;

      _message =
          'Data synchronization failed.\n\n$error';
    });
  }
}

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      title: const Text(
        'Category Data Sync',
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Text(_message),

          const SizedBox(height: 20),

          LinearProgressIndicator(
            value: _progress,
          ),

          if (!_isSyncing) ...[
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: HomeActionButton(
                    icon: _syncComplete
                        ? Icons.check
                        : Icons.sync,
                    label: _syncComplete
                        ? 'Done'
                        : 'Sync',
                    onTap: _syncComplete
                        ? () {
                            Navigator.of(
                              context,
                            ).pop();
                          }
                        : _startSync,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: HomeActionButton(
                    icon: Icons.close,
                    label: 'Cancel',
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}