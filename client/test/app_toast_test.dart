import 'package:client/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders AppToast at top floating below status bar/safe area', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  AppToast.show(
                    context,
                    message: 'ตำแหน่งฝึกงานใหม่พร้อมให้คุณสมัครแล้ว',
                    type: AppToastType.success,
                  );
                },
                child: const Text('Show Toast'),
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state: no toast
    expect(find.byType(AppToastOverlayWidget), findsNothing);

    // Tap to show toast
    await tester.tap(find.text('Show Toast'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 300)); // Finish entrance animation

    expect(find.byType(AppToastOverlayWidget), findsOneWidget);
    expect(find.text('ตำแหน่งฝึกงานใหม่พร้อมให้คุณสมัครแล้ว'), findsOneWidget);

    // Check position at the top
    final positionFinder = find.byType(Positioned);
    final positionedWidgets = tester.widgetList<Positioned>(positionFinder);
    final toastPositioned = positionedWidgets.firstWhere(
      (p) => p.child is Center,
    );
    // Since padding.top == 0 in default test environment, top should be 20.0
    expect(toastPositioned.top, 20.0);

    // Auto dismiss after duration
    await tester.pump(const Duration(milliseconds: 2800)); // Trigger timer
    await tester.pump(const Duration(milliseconds: 300)); // Finish exit animation
    expect(find.byType(AppToastOverlayWidget), findsNothing);
  });

  testWidgets('renders AppToast with top padding when SafeArea / StatusBar is present', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(top: 44.0)),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppToast.info(context, 'บันทึกสำเร็จ');
                  },
                  child: const Text('Show Info'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Info'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AppToastOverlayWidget), findsOneWidget);

    final positionFinder = find.byType(Positioned);
    final positionedWidgets = tester.widgetList<Positioned>(positionFinder);
    final toastPositioned = positionedWidgets.firstWhere(
      (p) => p.child is Center,
    );
    // With top padding 44, top should be 44 + 16 = 60.0
    expect(toastPositioned.top, 60.0);

    // Dismiss manually
    AppToast.dismiss(immediate: true);
    await tester.pump();
    expect(find.byType(AppToastOverlayWidget), findsNothing);
  });

  testWidgets('tap on close button dismisses AppToast', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  AppToast.warning(context, 'กรุณาตรวจสอบข้อมูล');
                },
                child: const Text('Show Warning'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Warning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('กรุณาตรวจสอบข้อมูล'), findsOneWidget);

    // Tap close button icon
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(); // Start reverse animation
    await tester.pump(const Duration(milliseconds: 250)); // Finish exit animation

    expect(find.byType(AppToastOverlayWidget), findsNothing);
  });

  testWidgets('showing new toast cleanly replaces previous toast', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => AppToast.info(context, 'ข้อความแรก'),
                  child: const Text('First'),
                ),
                ElevatedButton(
                  onPressed: () => AppToast.error(context, 'ข้อความที่สอง'),
                  child: const Text('Second'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('First'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ข้อความแรก'), findsOneWidget);

    // Show second immediately
    await tester.tap(find.text('Second'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // First is replaced, second is visible
    expect(find.text('ข้อความแรก'), findsNothing);
    expect(find.text('ข้อความที่สอง'), findsOneWidget);

    AppToast.dismiss(immediate: true);
    await tester.pump();
  });

  testWidgets('extension methods on BuildContext trigger toasts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => context.showSuccessToast('สำเร็จผ่าน Extension'),
              child: const Text('Extension Test'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Extension Test'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('สำเร็จผ่าน Extension'), findsOneWidget);

    AppToast.dismiss(immediate: true);
    await tester.pump();
  });
}
