import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../features/audio/presentation/screens/dashboard_screen.dart';
import '../../features/audio/presentation/widgets/animated_background.dart';
import '../../features/composer/presentation/screens/composer_screen.dart';

/// Top-level shell hosting the two MusicLens experiences:
///   * Analyze - existing audio analysis dashboard
///   * Compose - AI Music Compositor (LangGraph + procedural engine)
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  static const int _tabCount = 2;

  late final TabController _tabController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTabIndex.clamp(0, _tabCount - 1).toInt();
    _tabController = TabController(length: _tabCount, vsync: this);
    _tabController.index = _index;
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _index = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The DashboardScreen renders its own AnimatedBackground, so on the
          // Compose tab we render one here for visual continuity.
          if (_index == 1) const Positioned.fill(child: AnimatedBackground(child: SizedBox.shrink())),
          SafeArea(
            child: Column(
              children: [
                _buildTabBar(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      _AnalyzeTab(),
                      ComposerScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.buccaneer.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.tan.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cocoaBrown.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppTheme.primaryGradient,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppTheme.cocoaBrown,
          unselectedLabelColor: AppTheme.tan,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.graphic_eq_rounded, size: 18), text: 'Analyze'),
            Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: 'Compose'),
          ],
        ),
      ),
    );
  }
}

/// The Analyze tab simply hosts the existing dashboard. The dashboard renders
/// its own background and chrome, so we drop it directly inside the tab view.
class _AnalyzeTab extends StatelessWidget {
  const _AnalyzeTab();

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}
