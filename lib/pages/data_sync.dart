import 'package:flutter/material.dart';
import '../database/api_route_registry.dart';
import '../function/app_functions.dart';
import '../layout/layout.dart';
import '../widgets/authorization.dart';
import 'package:provider/provider.dart';
import '../session/session_provider.dart';
import '../services/access_control_service.dart';
import '../utils/global_colors.dart';

class DataSyncDialog extends StatefulWidget {
  const DataSyncDialog({super.key});

  @override
  State<DataSyncDialog> createState() => _DataSyncDialogState();
}

class _DataSyncDialogState extends State<DataSyncDialog> {
  double? _progress = 0;

  bool _isSyncing = false;
  bool _syncComplete = false;

  String _message = 'Do you want to synchronize categories now?';

  String _syncFailureMessage(Object error) {
    final text = error.toString().toLowerCase();
    final isHostLookupFailure =
        text.contains('failed host lookup') ||
        text.contains('no address associated with hostname') ||
        text.contains('failed to lookup') ||
        text.contains('socketexception');

    if (isHostLookupFailure) {
      return 'Unable to reach the sync server.\n\n'
          'Please check your internet connection or the server host configuration.';
    }

    return 'Data synchronization failed.\n\n$error';
  }

  Future<void> _showPermissionDeniedDialog() {
    return showDialog<void>(
      context: context,
      builder: (_) => const AuthorizationDialog(),
    );
  }

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
        _message = 'User group information is unavailable.';
      });

      return;
    }

    final allowed = await AccessControlService.checkAccess(
      groupCode: groupCode,
      screenId: AppFunctions.dataSyncScreen,
      functionId: AppFunctions.dataSync,
    );

    if (!allowed) {
      if (!mounted) {
        return;
      }

      await _showPermissionDeniedDialog();

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
        // A manual Data Sync is a full refresh: remove records that are no
        // longer returned by the server before saving this sync's data.
        clearExistingData: true,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }

          setState(() {
            _progress = progress.completedCount == 0 ? null : progress.value;

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
            'AppLicense: ${result.appLicense.savedCount}\n'
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

        _message = _syncFailureMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final layoutType = AppLayoutType.fromContext(context);
    final isMobile = layoutType.isMobile;
    final isTablet = layoutType.isTablet;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : isTablet ? 56 : 40,
        vertical: isTablet ? 32 : 24,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxDialogHeight = (constraints.maxHeight == double.infinity
                  ? screenSize.height * 0.9
                  : constraints.maxHeight)
              .clamp(280.0, screenSize.height * 0.9);

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 520 : 420,
              maxHeight: maxDialogHeight,
            ),
            child: Container(
              key: const ValueKey('data-sync-card'),
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 26 : isMobile ? 20 : 24),
              decoration: BoxDecoration(
                color: const Color(0xFF153C3F),
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
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Data Sync',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                          color: Colors.white,
                          icon: const Icon(Icons.close_rounded),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    Container(
                      padding: EdgeInsets.all(isTablet ? 16 : 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _message,
                        softWrap: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 22 : 18),
                    Row(
                      children: [
                        Icon(
                          Icons.sync,
                          color: const Color(0xFFAFBFC4),
                          size: isTablet ? 20 : 18,
                        ),
                        SizedBox(width: isTablet ? 10 : 8),
                        Text(
                          _isSyncing
                              ? 'Synchronizing...'
                              : (_syncComplete ? 'Completed' : 'Ready'),
                          style: TextStyle(
                            color: const Color(0xFFAFBFC4),
                            fontSize: isTablet ? 13 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 14 : 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF2C5C5F),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFF2D6A2),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    if (!_isSyncing) ...[
                      if (_syncComplete)
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.check),
                          label: const Text('Done'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: GlobalColors.buttonBackground,
                            minimumSize: const Size.fromHeight(56),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: _startSync,
                                icon: const Icon(Icons.sync),
                                label: const Text('Sync'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: GlobalColors.buttonBackground,
                                  minimumSize: const Size.fromHeight(56),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                                label: const Text('Cancel'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: GlobalColors.buttonBackground,
                                  minimumSize: const Size.fromHeight(56),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
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
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
