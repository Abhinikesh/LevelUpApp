import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepup_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: StepUpApp()),
    );
    // Verify the app renders without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
