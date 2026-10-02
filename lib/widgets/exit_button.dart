import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/global_colors.dart';

class ExitButton extends StatelessWidget {
  const ExitButton({super.key, this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: SystemNavigator.pop,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            alignment: Alignment.centerLeft,
            side: const BorderSide(color: GlobalColors.homeHeaderLabel),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
        ),
      );
    }

    return IconButton(
      tooltip: 'Exit',
      icon: const Icon(Icons.exit_to_app),
      onPressed: SystemNavigator.pop,
    );
  }
}
