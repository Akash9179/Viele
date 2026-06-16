import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viele/app.dart';

void main() {
  testWidgets('App boots into onboarding welcome', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VieleApp()));
    await tester.pump();

    expect(find.text('Outfits on people built like you.'), findsOneWidget);
    expect(find.text('Find my style'), findsOneWidget);
  });
}
