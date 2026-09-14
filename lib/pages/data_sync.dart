import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/button.dart';

class DataSyncDialog extends StatefulWidget {
	const DataSyncDialog({super.key});

	@override
	State<DataSyncDialog> createState() => _DataSyncDialogState();
}

class _DataSyncDialogState extends State<DataSyncDialog> {
	Timer? _progressTimer;
	double _progress = 0;
	bool _isSyncing = false;

	@override
	void dispose() {
		_progressTimer?.cancel();
		super.dispose();
	}

	void _startSync() {
		if (_isSyncing) return;

		setState(() {
			_isSyncing = true;
			_progress = 0;
		});

		_progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
			if (!mounted) {
				timer.cancel();
				return;
			}

			setState(() {
				_progress = (_progress + 0.05).clamp(0, 1);
			});

			if (_progress >= 1) {
				timer.cancel();
				setState(() {
					_isSyncing = false;
				});
			}
		});
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
						_isSyncing
								? 'Synchronizing data...'
								: 'Do you want to synchronize data now?',
					),
					const SizedBox(height: 20),
					LinearProgressIndicator(value: _progress),
					const SizedBox(height: 24),
					Row(
						children: [
              
              Expanded(

								child: HomeActionButton(
									icon: _progress >= 1 ? Icons.check : Icons.check_circle,
									label: _progress >= 1 ? 'Done' : 'Yes',
									onTap: _progress >= 1
											? () => Navigator.of(context).pop()
											: (_isSyncing ? () {} : _startSync),
								),
							),
							Expanded(
                
								child: HomeActionButton(
									icon: Icons.close,
									label: 'No',
									onTap: _isSyncing
											? () {}
											: () => Navigator.of(context).pop(),
								),
							),
							const SizedBox(width: 12),
							
						],
					),
				],
			),
		);
	}
}


