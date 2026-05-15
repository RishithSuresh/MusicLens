import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/landing/presentation/screens/landing_screen.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('renders MusicLens title', (WidgetTester tester) async {
    await tester.pumpWidget(const MusicLensApp());
    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.textContaining('DISCOVER'), findsOneWidget);
    expect(find.text('Launch Studio'), findsOneWidget);
  });
}
