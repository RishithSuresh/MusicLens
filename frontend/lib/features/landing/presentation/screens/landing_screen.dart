import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/home_shell.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _openStudio(BuildContext context, {int initialTabIndex = 0}) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 460),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (_, animation, secondaryAnimation) {
          // The route transition only uses the primary animation.
          // ignore: unused_local_variable
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.0),
                end: Offset.zero,
              ).animate(curved),
              child: HomeShell(initialTabIndex: initialTabIndex),
            ),
          );
        },
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatefulWidget {
  const _HeroPanel({
    required this.onLaunchAnalyze,
    required this.onLaunchCompose,
    required this.onHome,
    required this.onAnalyze,
    required this.onCompose,
    required this.onContact,
  });

  final VoidCallback onLaunchAnalyze;
  final VoidCallback onLaunchCompose;
  final VoidCallback onHome;
  final VoidCallback onAnalyze;
  final VoidCallback onCompose;
  final VoidCallback onContact;

  @override
  State<_HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<_HeroPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 940;
            final progress = _controller.value;

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
                      onHome: widget.onHome,
                      onAnalyze: widget.onAnalyze,
                      onCompose: widget.onCompose,
                      onContact: widget.onContact,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                      child: isWide
                          ? Row(
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: _HeroCopy(
                                    theme: theme,
                                    onLaunchAnalyze: widget.onLaunchAnalyze,
                                    onLaunchCompose: widget.onLaunchCompose,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 9,
                                  child: _HeroVisualPanel(progress: progress),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _HeroCopy(
                                  theme: theme,
                                  onLaunchAnalyze: widget.onLaunchAnalyze,
                                  onLaunchCompose: widget.onLaunchCompose,
                                ),
                                const SizedBox(height: 18),
                                const _HeroVisualPanel(progress: 0.35),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
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
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
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
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _DetailPill(label: 'BPM 128', icon: Icons.speed_rounded),
              _DetailPill(label: 'Key A minor', icon: Icons.music_note_rounded),
              _DetailPill(label: 'Live stems', icon: Icons.graphic_eq_rounded),
              _DetailPill(label: 'Studio FX', icon: Icons.multitrack_audio_rounded),
            ],
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

class _HeroVisualPanel extends StatelessWidget {
  const _HeroVisualPanel({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final pianoLift = math.sin(progress * math.pi * 2) * 10;
    final guitarLift = math.cos(progress * math.pi * 2 + math.pi / 3) * 12;
    final vinylSpin = progress * math.pi * 2 * 0.08;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.ivory,
            AppTheme.paper,
            AppTheme.tan.withValues(alpha: 0.26),
          ],
        ),
        border: Border.all(color: AppTheme.tan.withValues(alpha: 0.38)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MusicBackdropPainter(progress: progress),
              ),
            ),
            Positioned(
              right: -38,
              top: -18,
              child: _VinylOrb(rotation: vinylSpin),
            ),
            Positioned(
              left: 18,
              top: 18,
              child: _MiniBadge(
                label: 'Now playing',
                value: 'Pulse of brass',
                icon: Icons.graphic_eq_rounded,
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              top: 92,
              child: _InstrumentCard(
                title: 'Grand piano',
                subtitle: 'Warm chords and layered harmonics',
                imageUrl:
                    'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?auto=format&fit=crop&w=1200&q=80',
                accent: AppTheme.antiqueBrass,
                shift: Offset(0, pianoLift),
              ),
            ),
            Positioned(
              left: 24,
              right: 110,
              bottom: 22,
              child: _InstrumentCard(
                title: 'Electric guitar',
                subtitle: 'Riffs, texture, and rhythmic edge',
                imageUrl:
                    'https://images.unsplash.com/photo-1518972559570-7cc1309f3b45?auto=format&fit=crop&w=1200&q=80',
                accent: AppTheme.capePalliser,
                shift: Offset(0, guitarLift),
                compact: true,
              ),
            ),
            Positioned(
              right: 22,
              bottom: 32,
              child: _MetricCard(
                label: 'Tempo',
                value: '128 BPM',
                accent: AppTheme.buccaneer,
              ),
            ),
            Positioned(
              right: 22,
              top: 154,
              child: _MetricCard(
                label: 'Layer count',
                value: '8 stems',
                accent: AppTheme.cocoaBrown,
              ),
            ),
            Positioned(
              right: 22,
              bottom: 112,
              child: _FloatingNote(
                progress: progress,
                icon: Icons.music_note_rounded,
              ),
            ),
            Positioned(
              left: 110,
              bottom: 92,
              child: _FloatingNote(
                progress: progress + 0.18,
                icon: Icons.graphic_eq_rounded,
              ),
            ),
            Positioned(
              right: 92,
              top: 260,
              child: _FloatingNote(
                progress: progress + 0.42,
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstrumentCard extends StatelessWidget {
  const _InstrumentCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.accent,
    required this.shift,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final Color accent;
  final Offset shift;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: shift,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.ivory.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cocoaBrown.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: compact ? 92 : 108,
                  height: compact ? 92 : 108,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: accent.withValues(alpha: 0.12),
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: accent.withValues(alpha: 0.14),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.music_video_rounded,
                          color: accent,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.cocoaBrown,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.buccaneer.withValues(alpha: 0.84),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.ivory.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cocoaBrown.withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.buccaneer.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.cocoaBrown,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.ivory,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.tan.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.capePalliser),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.buccaneer,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cocoaBrown.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.tan),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.paper.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.ivory,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingNote extends StatelessWidget {
  const _FloatingNote({required this.progress, required this.icon});

  final double progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dx = math.sin(progress * math.pi * 2) * 6;
    final dy = math.cos(progress * math.pi * 2) * 8;
    final rotation = math.sin(progress * math.pi * 2) * 0.18;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.tan.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.buccaneer.withValues(alpha: 0.14)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.cocoaBrown.withValues(alpha: 0.78),
          ),
        ),
      ),
    );
  }
}

class _VinylOrb extends StatelessWidget {
  const _VinylOrb({required this.rotation});

  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 168,
        height: 168,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppTheme.cocoaBrown.withValues(alpha: 0.98),
              AppTheme.buccaneer.withValues(alpha: 0.95),
              AppTheme.capePalliser.withValues(alpha: 0.55),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cocoaBrown.withValues(alpha: 0.22),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.paper,
            ),
          ),
        ),
      ),
    );
  }
}

class _MusicBackdropPainter extends CustomPainter {
  const _MusicBackdropPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final shimmer = Paint()
      ..color = AppTheme.antiqueBrass.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final line = Paint()
      ..color = AppTheme.cocoaBrown.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (var i = 0; i < 5; i++) {
      final y = 74.0 + i * 78;
      final path = Path();
      for (double x = 0; x <= size.width; x += 8) {
        final wave = math.sin((x / 70) + progress * math.pi * 2 + i) * 8;
        final wave2 = math.cos((x / 90) + progress * math.pi * 2 + i * 0.6) * 4;
        final pointY = y + wave + wave2;
        if (x == 0) {
          path.moveTo(x, pointY);
        } else {
          path.lineTo(x, pointY);
        }
      }
      canvas.drawPath(path, shimmer);
    }

    for (var i = 0; i < 7; i++) {
      final x = 36.0 + i * 68;
      canvas.drawLine(Offset(x, 24), Offset(x, size.height - 24), line);
    }
  }

  @override
  bool shouldRepaint(covariant _MusicBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
