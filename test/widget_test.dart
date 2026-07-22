import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simasjid_app/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders phone and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Portal Ustadz/Ustadzah TPQ'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nomor HP'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Kata Sandi'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);
  });
}
