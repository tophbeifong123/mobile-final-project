import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash sends a signed-out session to Login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('ยินดีต้อนรับกลับมา!'), findsOneWidget);
  });
}
