import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FUDO V2')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Client Name: ', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 10),
                      Text('Log User: ', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 10),
                      Text('Client ID: ', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 10),
                      Text('Current Date: ', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 10),
                      Text('Time: ', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 10),
                      Text('Status: ', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 10),
                      Text('License valid: ', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 10),
                    ],
                  ),
                ),

                // Right side — action buttons (stacked vertically)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _actionButton(
                      icon: Icons.receipt_long,
                      label: 'Billing',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.dashboard,
                      label: 'Dashboard',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.bar_chart,
                      label: 'Reports',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.point_of_sale,
                      label: 'POS Setting',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.switch_account,
                      label: 'Change User',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.lock_reset,
                      label: 'Change Password',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.attach_money,
                      label: 'Cash Out',
                      onTap: () {},
                    ),
                    _actionButton(
                      icon: Icons.exit_to_app,
                      label: 'Exit',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 160,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
