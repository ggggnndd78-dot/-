import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghiyarak/app/app.dart';
import 'package:ghiyarak/features/splash/presentation/splash_page.dart';

void main() {
  testWidgets('Ghiyarak app renders splash page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GhiyarakApp()));

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pump();
  });
}
