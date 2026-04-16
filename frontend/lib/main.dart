import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/audio/presentation/screens/dashboard_screen.dart';

void main() {
  runApp(const MusicLensApp());
}

class MusicLensApp extends StatelessWidget {
  const MusicLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MusicLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}
