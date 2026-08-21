import 'package:flutter/material.dart';
import 'home_action_button.dart';

class HomeActionPanel extends StatelessWidget {
  const HomeActionPanel({
    super.key,
    required this.wrapButtons,
  });

  final bool wrapButtons;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      HomeActionButton(icon: Icons.receipt_long, label: 'Billing', onTap: () {}),
      HomeActionButton(icon: Icons.dashboard, label: 'Dashboard', onTap: () {}),
      HomeActionButton(icon: Icons.bar_chart, label: 'Reports', onTap: () {}),
      HomeActionButton(
        icon: Icons.point_of_sale,
        label: 'POS Setting',
        onTap: () {},
      ),
      HomeActionButton(
        icon: Icons.switch_account,
        label: 'Change User',
        onTap: () {},
      ),
      HomeActionButton(
        icon: Icons.lock_reset,
        label: 'Change Password',
        onTap: () {},
      ),
      HomeActionButton(
        icon: Icons.attach_money,
        label: 'Cash Out',
        onTap: () {},
      ),
    ];

    if (wrapButtons) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: buttons,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: buttons,
    );
  }
}
