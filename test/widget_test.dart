import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fudo_v2/main.dart';
import 'package:fudo_v2/pages/data_sync.dart';
import 'package:fudo_v2/session/session_provider.dart';
import 'package:fudo_v2/utils/global_colors.dart';
import 'package:fudo_v2/widgets/button.dart';
import 'package:fudo_v2/widgets/client_details.dart';

void main() {
  testWidgets('application starts', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('FUDO V2'), findsOneWidget);
  });

  testWidgets(
    'client detail fields place user, time, and license on the right',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            child: ClientDetails(
              clientName: 'Example Client',
              clientId: '123',
              userName: 'Operator',
              status: 'Active',
              licenseValid: 'Yes',
              currentDateTime: DateTime(2026, 9, 30, 12, 0),
            ),
          ),
        ),
      );

      final clientId = tester.getTopLeft(find.text('Client ID'));
      final user = tester.getTopLeft(find.text('Log User'));
      final date = tester.getTopLeft(find.text('Date'));
      final time = tester.getTopLeft(find.text('Time'));
      final status = tester.getTopLeft(find.text('Status'));
      final license = tester.getTopLeft(find.text('License valid'));

      expect(user.dx, greaterThan(clientId.dx));
      expect(time.dx, greaterThan(date.dx));
      expect(license.dx, greaterThan(status.dx));
      expect(user.dy, closeTo(clientId.dy, 0.1));
      expect(time.dy, closeTo(date.dy, 0.1));
      expect(license.dy, closeTo(status.dy, 0.1));
    },
  );

  testWidgets('data sync dialog renders without layout exceptions', (
    tester,
  ) async {
    final session = SessionProvider();
    session.setSession(
      clientId: '123',
      userId: 'u1',
      userName: 'Operator',
      groupCode: 'GROUP1',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>.value(
        value: session,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const DataSyncDialog(),
                    );
                  },
                  child: const Text('Open Sync'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sync'));
    await tester.pumpAndSettle();

    final dialogCard = find.byKey(const ValueKey('data-sync-card'));
    final dialogCardCenter = tester.getCenter(dialogCard);

    expect(find.text('Data Sync'), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
    expect(dialogCardCenter.dx, closeTo(400, 1));
    expect(dialogCardCenter.dy, closeTo(300, 1));
    expect(tester.getSize(dialogCard).width, lessThanOrEqualTo(420));
  });

  testWidgets('tablet action buttons use the shared default color except billing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1000, 700)),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: HomeActionButton(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                mode: HomeActionButtonMode.tile,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final button = tester.widget<TextButton>(find.byType(TextButton));
    final backgroundColor = button.style?.backgroundColor?.resolve({});

    expect(backgroundColor, GlobalColors.buttonBackground);
  });

  testWidgets('data sync dialog does not overflow on tablet layouts', (
    tester,
  ) async {
    final session = SessionProvider();
    session.setSession(
      clientId: '123',
      userId: 'u1',
      userName: 'Operator',
      groupCode: 'GROUP1',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>.value(
        value: session,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const DataSyncDialog(),
                    );
                  },
                  child: const Text('Open Sync'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sync'));
    await tester.pumpAndSettle();

    expect(find.text('Data Sync'), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
