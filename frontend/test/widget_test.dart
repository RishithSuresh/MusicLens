import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/widgets/home_shell.dart';
import 'package:frontend/features/landing/presentation/screens/landing_screen.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('renders MusicLens title', (WidgetTester tester) async {
    await tester.pumpWidget(const MusicLensApp());
    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.textContaining('DISCOVER'), findsOneWidget);
    expect(find.text('Launch Studio'), findsOneWidget);
  });

  testWidgets('home shell renders analyze and compose tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MusicLensApp());
    await tester.tap(find.text('Launch Studio'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Analyze'), findsWidgets);
    expect(find.text('Compose'), findsWidgets);
  });
}
