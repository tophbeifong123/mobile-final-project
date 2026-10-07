import 'package:client/features/auth/presentation/widgets/google_sign_in_button_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Google frame resizes without replacing the rendered button', (
    tester,
  ) async {
    double? renderedWidth;
    Element? originalButton;
    for (final screenWidth in [768.0, 390.0, 320.0, 390.0, 768.0]) {
      tester.view.physicalSize = Size(screenWidth, 844);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GoogleSignInButtonFrame(
                builder: (width) {
                  renderedWidth = width;
                  return SizedBox(key: ValueKey<double>(width));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final outerWidth = screenWidth - 64 > 400 ? 400.0 : screenWidth - 64;
      expect(renderedWidth, 376);
      final buttonFinder = find.byKey(ValueKey<double>(renderedWidth!));
      originalButton ??= tester.element(buttonFinder);
      expect(identical(tester.element(buttonFinder), originalButton), isTrue);
      final frame = tester.getRect(find.byType(Container));
      final button = tester.getRect(buttonFinder);
      expect(frame.width, outerWidth);
      expect(button.center.dx, frame.center.dx);
      expect(button.left, greaterThanOrEqualTo(frame.left + 12));
      expect(button.right, lessThanOrEqualTo(frame.right - 12));
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
