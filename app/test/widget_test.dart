import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viele/app.dart';

void main() {
  testWidgets('App boots into the Feed with the curated header', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VieleApp()));
    await tester.pump();

    expect(find.text('Viele'), findsOneWidget);
    expect(find.text('Outfits on people like you'), findsOneWidget);
    expect(find.text('RECOMMENDED'), findsOneWidget);
  });
}
