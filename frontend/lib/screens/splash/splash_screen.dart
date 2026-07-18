import 'dart:ui';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Phase 1: logo zoom-out + title reveal on the white screen
  late final AnimationController _introController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale; // zooms OUT: starts big -> settles
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _loaderOpacity;

  // Phase 2: white -> gold gradient sweep
  late final AnimationController _goldController;
  late final Animation<double> _goldOpacity;
  late final Animation<double> _goldWaveShift;

  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Logo starts zoomed-in (1.55x) and eases OUT down to its resting size.
    _logoOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(
      begin: 2.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _loaderOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
    );

    // The gold sweep: a soft curved edge rises up the screen, turning the
    // white backdrop into the gold gradient underneath it.
    _goldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _goldOpacity = CurvedAnimation(
      parent: _goldController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    _goldWaveShift = Tween<double>(begin: 1.15, end: -0.15).animate(
      CurvedAnimation(parent: _goldController, curve: Curves.easeInOutCubic),
    );

    _introController.forward();
    _scheduleSequence();
  }

  Future<void> _scheduleSequence() async {
    // Let the logo settle on white first.
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    // Sweep white -> gold.
    await _goldController.forward();
    if (!mounted) return;

    // Sit on the gold screen for a beat.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _exiting = true);
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    final isLoggedIn = SessionService.instance.currentUser != null;
    Navigator.of(context).pushReplacementNamed(
      isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _goldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedOpacity(
      opacity: _exiting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ---- Base: white/cream backdrop ----
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFAF7F0),
                    Color(0xFFF3ECDD),
                    Color(0xFFFFFFFF),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // ---- Gold gradient layer, revealed by a rising wave edge ----
            AnimatedBuilder(
              animation: _goldController,
              builder: (context, _) {
                return ClipPath(
                  clipper: _WaveClipper(shift: _goldWaveShift.value),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFEEDD82),
                          Color(0xFFD4AF37),
                          Color(0xFF996515),
                        ],
                        // colors: [
                        //   Color(0xFFF5D98A),
                        //   Color(0xFFD9AA4E),
                        //   Color(0xFFC79433),
                        // ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Soft ambient orbs (fade out once gold takes over)
            AnimatedBuilder(
              animation: _goldController,
              builder: (context, _) {
                final orbOpacity = 1.0 - _goldOpacity.value;
                return Opacity(
                  opacity: orbOpacity,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -80,
                        right: -60,
                        child:
                            _ambientOrb(240, AppColors.kGold.withOpacity(0.22)),
                      ),
                      Positioned(
                        bottom: -100,
                        left: -70,
                        child:
                            _ambientOrb(260, AppColors.kInfo.withOpacity(0.14)),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ---- Centered content: logo, title, loader ----
            AnimatedBuilder(
              animation: Listenable.merge([_introController, _goldController]),
              builder: (context, _) {
                final onGold = _goldOpacity.value; // 0 = white bg, 1 = gold bg
                final textColor = Color.lerp(
                  AppColors.kTextDark,
                  Colors.white,
                  onGold,
                )!;
                final subTextColor = Color.lerp(
                  AppColors.kTextMuted,
                  Colors.white.withOpacity(0.85),
                  onGold,
                )!;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 4),

                    // Logo: zooms out on entry, gets a brighter glow once gold appears
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Color.lerp(AppColors.kGold, Colors.white,
                                          onGold)!
                                      .withOpacity(0.35 + 0.15 * onGold),
                                  Color.lerp(AppColors.kGold, Colors.white,
                                          onGold)!
                                      .withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                          FadeTransition(
                            opacity: _logoOpacity,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Container(
                                width: 230,
                                height: 230,
                                padding: const EdgeInsets.all(12),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width:260, // Adjust this value to increase/decrease the logo size
                                    height:260, // Keep width and height equal to maintain aspect ratio
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Title
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: Text(
                          'FINANCE COLLECT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.2,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    FadeTransition(
                      opacity: _titleOpacity,
                      child: Text(
                        'LOAN & COLLECTION MANAGEMENT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.4,
                          color: subTextColor,
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    FadeTransition(
                      opacity: _loaderOpacity,
                      child: _PulsingDots(color: textColor),
                    ),

                    const SizedBox(height: 48),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _ambientOrb(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, color.withOpacity(0.0)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clips a soft diagonal wave. `shift` moves the wave from below the
/// screen (1.15 = fully hidden, all white showing) up past the top
/// (-0.15 = fully gone, all gold showing), giving the rising-curve sweep
/// from your reference image.
class _WaveClipper extends CustomClipper<Path> {
  _WaveClipper({required this.shift});
  final double shift; // 1.15 -> -0.15

  @override
  Path getClip(Size size) {
    final baseY = size.height * shift;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, baseY + size.height * 0.10);
    path.quadraticBezierTo(
      size.width * 0.28,
      baseY - size.height * 0.06,
      size.width * 0.55,
      baseY + size.height * 0.05,
    );
    path.quadraticBezierTo(
      size.width * 0.80,
      baseY + size.height * 0.14,
      size.width,
      baseY - size.height * 0.02,
    );
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WaveClipper oldClipper) =>
      oldClipper.shift != shift;
}

/// Three softly pulsing dots — recolors to match whichever background
/// (white or gold) is currently showing.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots({required this.color});
  final Color color;

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - (i * 0.2)) % 1.0;
            final scale = 0.6 + 0.4 * (0.5 - (t - 0.5).abs()) * 2;
            final opacity = 0.35 + 0.65 * (0.5 - (t - 0.5).abs()) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity.clamp(0.35, 1.0),
                child: Transform.scale(
                  scale: scale.clamp(0.6, 1.0),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
