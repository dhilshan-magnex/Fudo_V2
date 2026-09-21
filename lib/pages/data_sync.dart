import 'package:flutter/material.dart';
import '../api/category_api.dart';
import '../widgets/button.dart';

class DataSyncDialog extends StatefulWidget {
	const DataSyncDialog({super.key});

	@override
	State<DataSyncDialog> createState() => _DataSyncDialogState();
}

class _DataSyncDialogState extends State<DataSyncDialog> {
	final _categoryApi = CategoryApi();
	double? _progress = 0;
	bool _isSyncing = false;
	bool _syncComplete = false;
	String _message = 'Do you want to synchronize data now?';

	Future<void> _startSync() async {
		if (_isSyncing) return;

		setState(() {
			_isSyncing = true;
			_syncComplete = false;
			_progress = null;
			_message = 'Synchronizing data...';
		});

		try {
			final result = await _categoryApi.syncCategories(clearExistingData: true);

			if (!mounted) return;

			setState(() {
				_isSyncing = false;
				_syncComplete = true;
				_progress = 1;
				_message =
						'Synchronized L1 ${result.categoryLvl1}, L2 ${result.categoryLvl2}, L3 ${result.categoryLvl3}';
			});
		} catch (e) {
			if (!mounted) return;

			setState(() {
				_isSyncing = false;
				_syncComplete = false;
				_progress = 0;
				_message = 'Sync failed: $e';
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			title: Row(
				children: [
					const Expanded(child: Text('Data Sync')),
				],
			),
			content: Column(
				mainAxisSize: MainAxisSize.min,
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Text(
						_message,
					),
					const SizedBox(height: 20),
					LinearProgressIndicator(value: _progress),
					const SizedBox(height: 24),
					Row(
						children: [
							Expanded(
								child: HomeActionButton(
									icon: _syncComplete ? Icons.check : Icons.check_circle,
									label: _syncComplete ? 'Done' : 'Yes',
									onTap: _syncComplete
											? () => Navigator.of(context).pop()
											: (_isSyncing ? () {} : _startSync),
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: HomeActionButton(
									icon: Icons.close,
									label: 'No',
									onTap: _isSyncing
											? () {}
											: () => Navigator.of(context).pop(),
								),
							),
						],
					),
				],
			),
		);
	}
}


