import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kargah_yar/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('login shows workshop brand', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      ),
    );
    expect(find.text('GearPilot'), findsOneWidget);
    expect(find.textContaining('کارگاه'), findsWidgets);
  });
}
