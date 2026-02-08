import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhythm_pitch/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RhythmPitchApp()));

    // Verify the app loads with BPM display
    expect(find.text('BPM'), findsOneWidget);
  });
}
