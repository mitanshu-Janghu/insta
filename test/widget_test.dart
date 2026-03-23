import 'package:flutter_test/flutter_test.dart';

import 'package:insta_reel_gen/main.dart';

void main() {
  testWidgets('renders simplified reel generator workspace', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Reel Generator'), findsOneWidget);
    expect(
      find.text('Simple workflow for script, voice, edit, and export'),
      findsOneWidget,
    );
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Generate Script'), findsOneWidget);
    expect(
      find.text(
        'Create a reel for a cafe launch, product ad, fitness tip, or any other idea...',
      ),
      findsOneWidget,
    );
  });
}
