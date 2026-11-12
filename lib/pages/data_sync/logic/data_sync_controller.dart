part of '../data_sync_page.dart';

// Owns page state, lifecycle, and actions; layout is implemented by the view.
abstract class _DataSyncController extends State<DataSyncDialog> {
  double? _progress = 0;

  bool _isSyncing = false;
  bool _syncComplete = false;
  bool _syncFailed = false;

  String _message = 'Do you want to synchronize data now?';

  static const _syncErrorCode = 'SYNC-001';

  String _syncFailureMessage(Object error) => error is ApiSyncException
      ? error.toString()
      : 'Error code: $_syncErrorCode\n$error';

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
    final syncServerData = session.clientType?.trim() == '2';

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

    if (!mounted) return;
    setState(() {
      _isSyncing = true;
      _syncComplete = false;
      _syncFailed = false;
      _progress = null;
      _message = 'Starting data synchronization...';
    });

    try {
      final serverAddress = syncServerData
          ? await ServerSettings.getBaseUrl()
          : null;
      if (!mounted) return;
      if (syncServerData && serverAddress == null) {
        final saved = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _SyncServerDialog(),
        );
        if (!mounted) return;
        if (saved != true) {
          setState(() {
            _isSyncing = false;
            _progress = 0;
            _message = 'Set the API server address to synchronize data.';
          });
          return;
        }
      }
      final result = await ApiRouteRegistry.syncAll(
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

      final serverSummary = (syncServerData
          ? 'Users: ${result.users}\n'
                'User Groups: ${result.userGroups}\n'
                'User Setup: ${result.userSetup}\n'
                'Printers: ${result.printers}\n'
                'Customer Displays: ${result.customerDisplays}\n'
                'Cash Drawers: ${result.cashDrawers}\n'
          : 'Users, permissions and devices: using local data\n');

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
            '$serverSummary'
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
        _syncFailed = true;
        _progress = 0;

        _message = _syncFailureMessage(error);
      });
    }
  }
}
