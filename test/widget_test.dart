import 'package:flutter_test/flutter_test.dart';
import 'package:vibetrack/app.dart';

void main() {
  testWidgets('VibeTrack app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VibeTrackApp());

    // 验证应用能正常启动
    expect(find.text('VibeTrack'), findsOneWidget);
  });
}
