import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/global_colors.dart';
import 'app_button.dart';

class ExitButton extends StatelessWidget {
  const ExitButton({super.key, this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: AppButton(
          label: 'Log out',
          icon: Icons.logout_rounded,
          onPressed: SystemNavigator.pop,
          backgroundColor: GlobalColors.homeHeaderForeground,
          foregroundColor: GlobalColors.homeHeaderBackground,
          alignment: Alignment.centerLeft,
          borderRadius: 10,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          expand: true,
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
