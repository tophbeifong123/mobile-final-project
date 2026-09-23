import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/theme/app_colors_extension.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_card.dart';
import 'package:client/core/widgets/app_text_field.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('Design System - AppButton', () {
    testWidgets('renders button text correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppButton(
            text: 'คลิกที่นี่',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('คลิกที่นี่'), findsOneWidget);
    });

    testWidgets('fires onPressed callback when clicked', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          AppButton(
            text: 'กด',
            onPressed: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('กด'));
      expect(tapped, isTrue);
    });

    testWidgets('shows loading spinner when isLoading is true and ignores tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          AppButton(
            text: 'กำลังโหลด',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(tapped, isFalse);
    });

    testWidgets('renders all variants without throwing', (tester) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          buildTestableWidget(
            AppButton(
              text: variant.name,
              variant: variant,
              onPressed: () {},
            ),
          ),
        );
        expect(find.text(variant.name), findsOneWidget);
      }
    });

    testWidgets('respects isFullWidth option', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppButton(
            text: 'Full Width',
            isFullWidth: true,
            onPressed: () {},
          ),
        ),
      );

      final sizedBoxFinder = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == double.infinity,
      );
      expect(sizedBoxFinder, findsOneWidget);
    });
  });

  group('Design System - AppCard', () {
    testWidgets('renders child content and respects onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          AppCard(
            onTap: () => tapped = true,
            child: const Text('การ์ดข้อมูล'),
          ),
        ),
      );

      expect(find.text('การ์ดข้อมูล'), findsOneWidget);
      await tester.tap(find.text('การ์ดข้อมูล'));
      expect(tapped, isTrue);
    });

    testWidgets('applies border and custom colors', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppCard(
            backgroundColor: Colors.white,
            borderColor: Colors.black12,
            borderWidth: 2,
            child: Text('Card Content'),
          ),
        ),
      );

      final material = tester.widget<Material>(find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(Material),
      ));
      expect(material.color, Colors.white);
      expect(material.shape, isA<RoundedRectangleBorder>());
      final shape = material.shape as RoundedRectangleBorder;
      expect(shape.side.color, Colors.black12);
      expect(shape.side.width, 2.0);
    });
  });

  group('Design System - AppTextField', () {
    testWidgets('renders label and hintText correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppTextField(
            label: 'ชื่อผู้ใช้',
            hintText: 'กรุณากรอกชื่อผู้ใช้',
          ),
        ),
      );

      expect(find.text('ชื่อผู้ใช้'), findsOneWidget);
      expect(find.text('กรุณากรอกชื่อผู้ใช้'), findsOneWidget);
    });

    testWidgets('accepts user input and updates controller', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        buildTestableWidget(
          AppTextField(
            controller: controller,
            hintText: 'พิมพ์ที่นี่',
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'สวัสดี');
      expect(controller.text, 'สวัสดี');
    });

    testWidgets('shows validation error when form validates', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        buildTestableWidget(
          Form(
            key: formKey,
            child: AppTextField(
              label: 'อีเมล',
              validator: (val) => (val == null || val.isEmpty) ? 'กรุณากรอกอีเมล' : null,
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
    });
  });

  group('Design System - AppColorsExtension', () {
    testWidgets('provides design tokens through context.colors', (tester) async {
      late AppColorsExtension colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              colors = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(colors.border, isNotNull);
      expect(colors.muted, isNotNull);
      expect(colors.mutedForeground, isNotNull);
      expect(colors.ring, isNotNull);
      expect(colors.destructive, isNotNull);
    });
  });
}
