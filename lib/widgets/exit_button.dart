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
            backgroundColor: GlobalColors.homeHeaderForeground,
            foregroundColor: GlobalColors.homeHeaderBackground,
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
        ),
      );
    }

    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: GlobalColors.homeHeaderForeground,
        foregroundColor: GlobalColors.homeHeaderBackground,
      ),
      tooltip: 'Exit',
      icon: const Icon(Icons.exit_to_app),
      onPressed: SystemNavigator.pop,
    );
  }
}
