import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('renders MusicLens title', (WidgetTester tester) async {
    await tester.pumpWidget(const MusicLensApp());
    expect(find.textContaining('Music'), findsAtLeastNWidgets(1));
  });
}
