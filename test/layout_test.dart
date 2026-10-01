import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/layout/layout.dart';
import 'package:fudo_v2/layout/mobile_layout.dart';

void main() {
  testWidgets('responsive home layout renders primary and side content', (
    tester,
  ) async {
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

  testWidgets('home layout places side content beside primary in landscape', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 800,
            height: 500,
            child: HomeLayout(
              primaryContent: const Text(
                'Primary content',
                key: Key('primary'),
              ),
              sideContent: const Text('Side content', key: Key('side')),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(const Key('primary'))).dy,
      tester.getTopLeft(find.byKey(const Key('side'))).dy,
    );
  });

  testWidgets('mobile layout stacks content in portrait', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 360,
            height: 640,
            child: MobileLayout(
              primaryContent: const Text(
                'Primary content',
                key: Key('primary'),
              ),
              sideContent: const Text('Side content', key: Key('side')),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(const Key('side'))).dy,
      greaterThan(tester.getTopLeft(find.byKey(const Key('primary'))).dy),
    );
  });

  testWidgets('mobile layout supports LayoutBuilder content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 640,
          child: MobileLayout(
            primaryContent: LayoutBuilder(
              builder: (context, constraints) => const Text('Primary content'),
            ),
            sideContent: LayoutBuilder(
              builder: (context, constraints) => const Text('Side content'),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
