import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/pages/data_sync/data_sync_page.dart';
import 'package:fudo_v2/pages/dinein/dinein_page.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    testWidgets('Data Sync opens and cancels at ${size.width}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const DataSyncDialog(),
                ),
                child: const Text('Open sync'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open sync'));
      await tester.pumpAndSettle();

      expect(find.text('Do you want to synchronize data now?'), findsOneWidget);
      expect(find.text('Sync'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(DataSyncDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  test('Moved menu models preserve database conversion and public access', () {
    final item = DineInMenuItem.fromRow({
      'Menu_ID': ' M1 ',
      'Menu_Name': ' Rice ',
      'Menu_Price': '125.50',
      'Display_Order_ID': '3',
      'Dine': 'yes',
    });
    expect(item.id, 'M1');
    expect(item.name, 'Rice');
    expect(item.price, 125.5);
    expect(item.order, 3);
    expect(item.isAvailableForDineIn, isTrue);
    expect(DineInMenuItem.fromRow({'Dine': '0'}).isAvailableForDineIn, isFalse);

    final category = DineInCategory.fromRow({'Cat_Code': ' C1 '});
    expect(category.code, 'C1');
    expect(category.name, 'C1');
  });
}
