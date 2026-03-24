import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insta_reel_gen/main.dart';

void main() {
  testWidgets('renders reel generator mobile workspace', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Reel Generator'), findsOneWidget);
    expect(find.text('ChatGPT-style mobile workspace'), findsOneWidget);
    expect(find.text('How it works'), findsOneWidget);
    expect(find.byKey(const Key('prompt_input')), findsOneWidget);
    expect(find.byKey(const Key('send_button')), findsOneWidget);
  });
}
