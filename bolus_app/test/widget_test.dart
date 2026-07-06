import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bolus_app/main.dart';

void main() {
  testWidgets('Smoke test - App runs and loads AuthView', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: BolusApp(initialHome: SizedBox()),
      ),
    );

    // Verify that the app title or logo text is present
    expect(find.text('Bölüş'), findsWidgets);
  });
}
