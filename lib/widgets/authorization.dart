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
		return Center(
			child: Material(
				color: Colors.white,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(18),
				),
				child: Padding(
					padding: const EdgeInsets.all(20),
					child: ConstrainedBox(
						constraints: const BoxConstraints(maxWidth: 360),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									title,
									style: const TextStyle(
										fontSize: 20,
										fontWeight: FontWeight.w700,
									),
								),
								const SizedBox(height: 12),
								Text(message),
								const SizedBox(height: 18),
								Align(
									alignment: Alignment.centerRight,
									child: TextButton(
										onPressed: () => Navigator.of(context).pop(),
										child: const Text('OK'),
									),
								),
							],
						),
					),
				),
			),
		);
	}
}
