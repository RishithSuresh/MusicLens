import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/home_shell.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _openStudio(BuildContext context, {int initialTabIndex = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeShell(initialTabIndex: initialTabIndex),
      ),
    );
  }

  void _showContact(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact us at team.musiclens@gmail.com'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.tan, AppTheme.antiqueBrass],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _HeroPanel(
                  onLaunchAnalyze: () => _openStudio(context),
                  onLaunchCompose: () => _openStudio(context, initialTabIndex: 1),
                  onHome: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You are on the MusicLens home page.')),
                    );
                  },
                  onAnalyze: () => _openStudio(context),
                  onCompose: () => _openStudio(context, initialTabIndex: 1),
                  onContact: () => _showContact(context),
                  onBookDemo: () => _showContact(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.onLaunchAnalyze,
    required this.onLaunchCompose,
    required this.onHome,
    required this.onAnalyze,
    required this.onCompose,
    required this.onContact,
    required this.onBookDemo,
  });

  final VoidCallback onLaunchAnalyze;
  final VoidCallback onLaunchCompose;
  final VoidCallback onHome;
  final VoidCallback onAnalyze;
  final VoidCallback onCompose;
  final VoidCallback onContact;
  final VoidCallback onBookDemo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 940;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.paper,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cocoaBrown.withValues(alpha: 0.32),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: _TopNav(
                  onHome: onHome,
                  onAnalyze: onAnalyze,
                  onCompose: onCompose,
                  onContact: onContact,
                ),
              ),
              Expanded(
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: _HeroCopy(
                              theme: theme,
                              onLaunchAnalyze: onLaunchAnalyze,
                              onLaunchCompose: onLaunchCompose,
                            ),
                          ),
                          Expanded(child: const _HeroArt()),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _HeroCopy(
                              theme: theme,
                              onLaunchAnalyze: onLaunchAnalyze,
                              onLaunchCompose: onLaunchCompose,
                            ),
                          ),
                          SizedBox(height: 270, child: const _HeroArt()),
                        ],
                      ),
              ),
              _PromoStrip(onBookDemo: onBookDemo),
            ],
          ),
        );
      },
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({
    required this.onHome,
    required this.onAnalyze,
    required this.onCompose,
    required this.onContact,
  });

  final VoidCallback onHome;
  final VoidCallback onAnalyze;
  final VoidCallback onCompose;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            children: const [
              TextSpan(
                text: 'Music',
                style: TextStyle(
                  color: AppTheme.cocoaBrown,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Lens',
                style: TextStyle(
                  color: AppTheme.antiqueBrass,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.ivory,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Wrap(
            spacing: 8,
            children: [
              _NavChip(label: 'Home', onTap: onHome),
              _NavChip(label: 'Analyze', onTap: onAnalyze),
              _NavChip(label: 'Compose', onTap: onCompose),
              _NavChip(label: 'Contact', onTap: onContact),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.tan.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.buccaneer,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.theme,
    required this.onLaunchAnalyze,
    required this.onLaunchCompose,
  });

  final ThemeData theme;
  final VoidCallback onLaunchAnalyze;
  final VoidCallback onLaunchCompose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 10, 26, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'DISCOVER',
            style: theme.textTheme.displayMedium?.copyWith(
              color: AppTheme.cocoaBrown,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          Text(
            'MUSIC IN MOTION',
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppTheme.buccaneer,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Turn every track into an immersive visual story. Analyze beats, '
            'decode patterns, and compose your next signature sound with a stage-ready workflow.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.buccaneer.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onLaunchAnalyze,
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text('Launch Studio'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.antiqueBrass,
                  foregroundColor: AppTheme.cocoaBrown,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onLaunchCompose,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Try Composer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.buccaneer,
                  side: BorderSide(color: AppTheme.buccaneer.withValues(alpha: 0.35)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 10, 10),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(70),
          bottomRight: Radius.circular(28),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC03B), Color(0xFFFFA615)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -42,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 30,
            top: 32,
            child: Container(
              width: 95,
              height: 95,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.buccaneer,
              ),
              child: const Center(
                child: Icon(
                  Icons.album_rounded,
                  size: 54,
                  color: AppTheme.paper,
                ),
              ),
            ),
          ),
          const Positioned(
            top: 56,
            right: 28,
            child: Icon(
              Icons.headphones_rounded,
              size: 70,
              color: AppTheme.cocoaBrown,
            ),
          ),
          Positioned(
            left: 30,
            right: 30,
            bottom: 26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.graphic_eq_rounded, color: AppTheme.cocoaBrown),
                  SizedBox(width: 10),
                  Text(
                    'Real-time waveform • beat sync • AI composition',
                    style: TextStyle(
                      color: AppTheme.cocoaBrown,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoStrip extends StatelessWidget {
  const _PromoStrip({required this.onBookDemo});

  final VoidCallback onBookDemo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6D37D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const _OfferTile(
            title: '20% OFF',
            subtitle: 'Early access for first 100 creators',
            emphasis: true,
          ),
          const _OfferTile(
            title: 'Analyze',
            subtitle: 'Upload songs and unlock musical DNA',
          ),
          const _OfferTile(
            title: 'Compose',
            subtitle: 'Generate melody ideas from plain language',
          ),
          _OfferTile(
            title: 'Book Demo',
            subtitle: 'See MusicLens live with guided setup',
            action: true,
            onTap: onBookDemo,
          ),
        ],
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.title,
    required this.subtitle,
    this.emphasis = false,
    this.action = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool emphasis;
  final bool action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minWidth: 210, maxWidth: 290),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (emphasis)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.local_offer_rounded, color: AppTheme.cocoaBrown),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.cocoaBrown,
                      fontWeight: FontWeight.w900,
                      fontSize: emphasis ? 28 : 18,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.buccaneer,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (action)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.arrow_forward_rounded, color: AppTheme.cocoaBrown),
              ),
          ],
        ),
      ),
    );
  }
}
