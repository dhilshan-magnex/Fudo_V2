import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fudo_v2/main.dart';
import 'package:fudo_v2/widgets/client_details.dart';

void main() {
  testWidgets('application starts', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('FUDO V2'), findsOneWidget);
  });

  testWidgets('client detail fields are laid out in one column', (
    tester,
  ) async {
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

    final clientIdY = tester.getTopLeft(find.text('Client ID')).dy;
    final clientIdValueRight = tester.getTopRight(find.text('123')).dx;
    final userNameValueRight = tester.getTopRight(find.text('Operator')).dx;
    final dateValueRight = tester.getTopRight(find.text('30/09/2026')).dx;
    final timeValueRight = tester.getTopRight(find.text('12:00:00')).dx;
    final statusValueRight = tester.getTopRight(find.text('Active')).dx;
    final licenseValueRight = tester.getTopRight(find.text('Yes')).dx;
    final userNameY = tester.getTopLeft(find.text('Log User')).dy;
    final dateY = tester.getTopLeft(find.text('Date')).dy;
    final timeY = tester.getTopLeft(find.text('Time')).dy;
    final statusY = tester.getTopLeft(find.text('Status')).dy;
    final licenseY = tester.getTopLeft(find.text('License valid')).dy;

    expect(userNameY, greaterThan(clientIdY));
    expect(userNameValueRight, closeTo(clientIdValueRight, 0.1));
    expect(dateValueRight, closeTo(clientIdValueRight, 0.1));
    expect(timeValueRight, closeTo(clientIdValueRight, 0.1));
    expect(statusValueRight, closeTo(clientIdValueRight, 0.1));
    expect(licenseValueRight, closeTo(clientIdValueRight, 0.1));
    expect(dateY, greaterThan(userNameY));
    expect(timeY, greaterThan(dateY));
    expect(statusY, greaterThan(timeY));
    expect(licenseY, greaterThan(statusY));
  });
}
