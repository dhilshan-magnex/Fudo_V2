import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/client_service.dart';
import '../session/session_provider.dart';
import 'data_sync.dart';
import 'billing/billing_page.dart';
import '../widgets/client_details.dart';
import '../widgets/buttons/exit_button.dart';
import '../widgets/buttons/button.dart';
import '../layout/layout.dart';
import '../utils/global_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _clientService = ClientService();

  void _openDataSync() {
    showDialog<void>(context: context, builder: (_) => const DataSyncDialog());
  }

  List<HomeActionButton> _homeButtons(BuildContext context) => [
    HomeActionButton(
      icon: Icons.receipt_long_outlined,
      label: 'Billing',
      subtitle: 'Start a new sale',
      mode: HomeActionButtonMode.featured,
      backgroundColor: GlobalColors.billingButtonBackground,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BillingPage()),
      ),
    ),
    HomeActionButton(
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
      mode: HomeActionButtonMode.tile,
      backgroundColor: GlobalColors.homeActionBackground,
      onTap: _emptyAction,
    ),
    HomeActionButton(
      icon: Icons.bar_chart,
      label: 'Reports',
      mode: HomeActionButtonMode.tile,
      backgroundColor: GlobalColors.homeActionBackground,
      onTap: _emptyAction,
    ),
    HomeActionButton(
      icon: Icons.attach_money,
      label: 'Cash Out',
      mode: HomeActionButtonMode.tile,
      backgroundColor: GlobalColors.homeActionBackground,
      onTap: _emptyAction,
    ),
    HomeActionButton(
      icon: Icons.sync,
      label: 'Data Sync',
      mode: HomeActionButtonMode.tile,
      backgroundColor: GlobalColors.homeActionBackground,
      onTap: _openDataSync,
    ),
    HomeActionButton(
      icon: Icons.tune,
      label: 'POS Setting',
      mode: HomeActionButtonMode.compact,
      backgroundColor: GlobalColors.homeActionBackground,
      onTap: _emptyAction,
    ),
    HomeActionButton(
      icon: Icons.person_outline,
      label: 'Change User',
      mode: HomeActionButtonMode.compact,
      backgroundColor: GlobalColors.homeActionBackground,
      onTap: _emptyAction,
    ),
    HomeActionButton(
      icon: Icons.lock_outline,
      label: 'Change Password',
      mode: HomeActionButtonMode.compact,
      backgroundColor: GlobalColors.homeActionBackground,
      onTap: _emptyAction,
    ),
  ];

  static void _emptyAction() {}

  late final Future<Map<String, dynamic>?> _clientInfoFuture;

  late DateTime _now;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _clientInfoFuture = _clientService.getClientInfo();

    _now = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutType = AppLayoutType.fromContext(context);
    final isMobile = layoutType.isMobile;
    final isTablet = layoutType.isTablet;

    return Scaffold(
      backgroundColor: GlobalColors.homeBackground,
      body: HomeLayout(
          primaryContent: FutureBuilder<Map<String, dynamic>?>(
            future: _clientInfoFuture,
            builder: (context, snapshot) {
              final clientInfo = snapshot.data;
              final session = context.watch<SessionProvider>();

              final clientDetails = ClientDetails(
                clientName:
                    session.clientName ??
                    clientInfo?['Client_Name']?.toString() ??
                    '',
                clientId:
                    session.clientId ??
                    clientInfo?['Client_ID']?.toString() ??
                    '',
                userName: session.userName ?? '',
                status: clientInfo?['Status']?.toString() ?? '',
                licenseValid: clientInfo?['License_valid']?.toString() ?? '',
                currentDateTime: _now,
                mobileHeader: isMobile,
                tabletHeader: isTablet,
                desktopHeader: layoutType.isDesktop,
              );

              if (isTablet) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'FUDO V2',
                            style: TextStyle(
                              color: GlobalColors.homeHeaderForeground,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: GlobalColors.homeHeaderLabel,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const IconTheme(
                            data: IconThemeData(
                              color: GlobalColors.homeHeaderForeground,
                            ),
                            child: ExitButton(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    clientDetails,
                  ],
                );
              }

              if (!isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'FUDO V2',
                      style: TextStyle(
                        color: GlobalColors.homeHeaderForeground,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Expanded(child: clientDetails),
                    const SizedBox(height: 28),
                    const ExitButton(expanded: true),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'FUDO V2',
                          style: TextStyle(
                            color: GlobalColors.homeHeaderForeground,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: GlobalColors.homeHeaderLabel,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IconTheme(
                          data: const IconThemeData(
                            color: GlobalColors.homeHeaderForeground,
                          ),
                          child: const ExitButton(),
                        ),
                      ),
                    ],
                  ),
                  clientDetails,
                ],
              );
            },
          ),
          sideContent: HomeActionPanel(
            wrapButtons: true,
            buttons: _homeButtons(context),
          ),
      ),
    );
  }
}
