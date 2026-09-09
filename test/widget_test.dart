import 'package:flutter_test/flutter_test.dart';

import 'package:fudo_v2/main.dart';

void main() {
  testWidgets('application starts', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('FUDO V2'), findsOneWidget);
  });
}
