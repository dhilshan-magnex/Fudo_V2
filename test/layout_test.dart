import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/layout/layout.dart';

void main() {
  testWidgets('responsive home layout renders primary and side content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeLayout(
          primaryContent: const Text('Primary content'),
          sideContent: const Text('Side content'),
        ),
      ),
    );

    expect(find.text('Primary content'), findsOneWidget);
    expect(find.text('Side content'), findsOneWidget);
  });
}
