import 'package:flutter/material.dart';

class AuthorizationDialog extends StatelessWidget {
	const AuthorizationDialog({
		super.key,
		this.title = 'Access denied',
		this.message = 'You do not have permission to use this feature.',
	});

	final String title;
	final String message;

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			title: Text(title),
			content: Text(message),
			actions: [
				TextButton(
					onPressed: () => Navigator.of(context).pop(),
					child: const Text('OK'),
				),
			],
		);
	}
}
