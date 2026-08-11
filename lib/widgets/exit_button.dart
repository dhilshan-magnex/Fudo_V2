import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExitButton extends StatelessWidget {
  const ExitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Exit',
      icon: const Icon(Icons.exit_to_app),
      onPressed: SystemNavigator.pop,
    );
  }
}
