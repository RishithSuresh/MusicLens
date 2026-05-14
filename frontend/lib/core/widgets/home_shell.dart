import 'package:flutter/material.dart';

import '../../features/audio/presentation/screens/dashboard_screen.dart';
import '../../features/audio/presentation/widgets/animated_background.dart';
import '../../features/composer/presentation/screens/composer_screen.dart';

/// Top-level shell hosting the two MusicLens experiences:
///   * Analyze - existing audio analysis dashboard
///   * Compose - AI Music Compositor (LangGraph + procedural engine)
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF475569),
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
