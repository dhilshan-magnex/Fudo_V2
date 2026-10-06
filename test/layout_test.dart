import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/layout/layout.dart';
import 'package:fudo_v2/layout/mobile_layout.dart';
import 'package:fudo_v2/layout/tablet_layout.dart';
import 'package:fudo_v2/utils/global_colors.dart';
import 'package:fudo_v2/widgets/button.dart';
import 'package:fudo_v2/widgets/client_details.dart';

void main() {
  test('layout type centralizes platform and breakpoint selection', () {
    expect(
      AppLayoutType.resolve(
        maxWidth: 360,
        screenSize: const Size(360, 640),
        platform: TargetPlatform.android,
      ),
      AppLayoutType.mobile,
    );
    expect(
      AppLayoutType.resolve(
        maxWidth: 800,
        screenSize: const Size(800, 1024),
        platform: TargetPlatform.android,
      ),
      AppLayoutType.tablet,
    );
    expect(
      AppLayoutType.resolve(
        maxWidth: 1600,
        screenSize: const Size(1600, 900),
        platform: TargetPlatform.windows,
      ),
      AppLayoutType.desktop,
    );
    expect(
      AppLayoutType.resolve(
        maxWidth: 1600,
        screenSize: const Size(1600, 900),
        platform: TargetPlatform.android,
      ),
      AppLayoutType.tablet,
    );
  });

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
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 800)),
          child: Center(
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
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(const Key('side'))).dy,
      greaterThan(tester.getTopLeft(find.byKey(const Key('primary'))).dy),
    );
  });

  testWidgets('large landscape Android tablet uses tablet layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: HomeLayout(
          primaryContent: const Text('Client rail'),
          sideContent: const Text('Action board'),
        ),
      ),
    );

    expect(find.byType(TabletLayout), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  testWidgets('mobile home fits a phone viewport without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final buttons = [
      HomeActionButton(
        icon: Icons.receipt_long,
        label: 'Billing',
        subtitle: 'Start a new sale',
        mode: HomeActionButtonMode.featured,
        onTap: () {},
      ),
      for (final label in ['Dashboard', 'Reports', 'Cash Out', 'Data Sync'])
        HomeActionButton(
          icon: Icons.dashboard,
          label: label,
          mode: HomeActionButtonMode.tile,
          onTap: () {},
        ),
      for (final label in ['POS Setting', 'Change User', 'Change Password'])
        HomeActionButton(
          icon: Icons.settings,
          label: label,
          mode: HomeActionButtonMode.compact,
          onTap: () {},
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MobileLayout(
          primaryContent: const SizedBox(
            height: 260,
            child: Text('Home header'),
          ),
          sideContent: HomeActionPanel(wrapButtons: true, buttons: buttons),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(
      tester.getBottomRight(find.text('Change Password')).dy,
      lessThanOrEqualTo(800),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact home action fits a short button constraint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 138,
              height: 50,
              child: HomeActionButton(
                icon: Icons.lock_outline,
                label: 'Change Password',
                mode: HomeActionButtonMode.compact,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Change Password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Billing is red while other actions keep their default color', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 120,
                child: HomeActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Billing',
                  mode: HomeActionButtonMode.featured,
                  backgroundColor: GlobalColors.billingButtonBackground,
                  onTap: () {},
                ),
              ),
              SizedBox(
                height: 100,
                child: HomeActionButton(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final billingButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Billing'),
    );
    final dashboardButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Dashboard'),
    );

    expect(
      billingButton.style?.backgroundColor?.resolve({}),
      GlobalColors.billingButtonBackground,
    );
    expect(
      dashboardButton.style?.backgroundColor?.resolve({}),
      GlobalColors.buttonBackground,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet action panel features and aligns Billing first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final buttons = [
      HomeActionButton(
        icon: Icons.receipt_long_outlined,
        label: 'Billing',
        subtitle: 'Start a new order',
        mode: HomeActionButtonMode.featured,
        backgroundColor: GlobalColors.billingButtonBackground,
        onTap: () {},
      ),
      for (final label in ['Dashboard', 'Reports', 'Cash Out', 'Data Sync'])
        HomeActionButton(
          icon: Icons.dashboard_outlined,
          label: label,
          mode: HomeActionButtonMode.tile,
          onTap: () {},
        ),
      for (final label in ['POS Setting', 'Change User', 'Change Password'])
        HomeActionButton(
          icon: Icons.tune,
          label: label,
          mode: HomeActionButtonMode.compact,
          onTap: () {},
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 672,
              height: 704,
              child: HomeActionPanel(wrapButtons: true, buttons: buttons),
            ),
          ),
        ),
      ),
    );

    final billing = find.widgetWithText(TextButton, 'Billing');
    final dashboard = find.widgetWithText(TextButton, 'Dashboard');
    final posSetting = find.widgetWithText(TextButton, 'POS Setting');
    final billingSize = tester.getSize(billing);
    final dashboardSize = tester.getSize(dashboard);
    final billingButton = tester.widget<TextButton>(billing);
    final dashboardButton = tester.widget<TextButton>(dashboard);
    final posSettingButton = tester.widget<TextButton>(posSetting);

    expect(billingSize.width, closeTo(442.7, 1));
    expect(billingSize.width, greaterThan(dashboardSize.width));
    expect(dashboardSize.width, closeTo(213.3, 1));
    expect(
      billingButton.style?.backgroundColor?.resolve({}),
      GlobalColors.billingButtonBackground,
    );
    expect(
      dashboardButton.style?.backgroundColor?.resolve({}),
      GlobalColors.homeHeaderBackground,
    );
    expect(posSettingButton.style?.backgroundColor?.resolve({}), Colors.white);
    expect(
      tester.getTopLeft(billing).dy,
      closeTo(tester.getTopLeft(dashboard).dy, 0.1),
    );
    expect(
      tester.getTopLeft(find.widgetWithText(TextButton, 'Reports')).dy,
      greaterThan(tester.getTopLeft(billing).dy),
    );
    expect(
      tester.getTopLeft(find.widgetWithText(TextButton, 'POS Setting')).dy,
      greaterThan(
        tester.getTopLeft(find.widgetWithText(TextButton, 'Reports')).dy,
      ),
    );
    expect(find.text('Start a new order'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tile home action fits the reported short height', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 138,
              height: 54,
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

    expect(find.text('Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile client detail columns keep their horizontal alignment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(viewPadding: EdgeInsets.only(top: 24)),
          child: MobileLayout(
            primaryContent: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('FUDO V2')),
                    const SizedBox(width: 48, height: 48),
                  ],
                ),
                ClientDetails(
                  clientName: 'ABC Trading Pvt Ltd',
                  clientId: '001',
                  userName: 'admin',
                  status: 'Not set',
                  licenseValid: 'Not set',
                  currentDateTime: DateTime(2026, 9, 30, 14, 55, 1),
                  mobileHeader: true,
                ),
              ],
            ),
            sideContent: const SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('USER')).dx, greaterThan(180));
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape phone fits the home design without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final buttons = [
      HomeActionButton(
        icon: Icons.receipt_long_outlined,
        label: 'Billing',
        subtitle: 'Start a new sale',
        mode: HomeActionButtonMode.featured,
        onTap: () {},
      ),
      for (final label in ['Dashboard', 'Reports', 'Cash Out', 'Data Sync'])
        HomeActionButton(
          icon: Icons.dashboard_outlined,
          label: label,
          mode: HomeActionButtonMode.tile,
          onTap: () {},
        ),
      for (final label in ['POS Setting', 'Change User', 'Change Password'])
        HomeActionButton(
          icon: Icons.tune,
          label: label,
          mode: HomeActionButtonMode.compact,
          onTap: () {},
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: HomeLayout(
          primaryContent: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('FUDO V2')),
                  const SizedBox(width: 48, height: 48),
                ],
              ),
              ClientDetails(
                clientName: 'ABC Trading Pvt Ltd',
                clientId: '001',
                userName: 'admin',
                status: 'Not set',
                licenseValid: 'Not set',
                currentDateTime: DateTime(2026, 9, 30, 14, 55, 1),
                mobileHeader: true,
              ),
            ],
          ),
          sideContent: HomeActionPanel(wrapButtons: true, buttons: buttons),
        ),
      ),
    );

    expect(find.byType(MobileLayout), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(
      tester.getSize(find.byType(HomeActionPanel)).width,
      greaterThan(tester.getSize(find.byType(ClientDetails)).width),
    );
    expect(
      tester.getBottomRight(find.text('Change Password')).dy,
      lessThanOrEqualTo(360),
    );
    expect(tester.takeException(), isNull);
  });
}
