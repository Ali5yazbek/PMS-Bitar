// ─── Luxury Obsidian & Royal Teal/Gold Animated Splash Screen ─────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _companySlide;
  late Animation<double> _companyOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _pulseGlow;

  String _statusText = 'Securing Enterprise Channel...';
  double _progressValue = 0.18;
  Timer? _timer1;
  Timer? _timer2;
  Timer? _navigateTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _companySlide = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _companyOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.60, curve: Curves.easeIn),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.75, curve: Curves.easeIn),
      ),
    );

    _pulseGlow = Tween<double>(begin: 0.35, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    _timer1 = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _statusText = 'Synchronizing Portfolio & Assets...';
          _progressValue = 0.75;
        });
      }
    });

    _timer2 = Timer(const Duration(milliseconds: 240), () {
      if (mounted) {
        setState(() {
          _statusText = 'Initializing SOCIMCO Engine...';
          _progressValue = 1.0;
        });
      }
    });

    _navigateTimer = Timer(const Duration(milliseconds: 360), _navigateToApp);
  }

  void _navigateToApp() {
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.isLoading) {
      Future.delayed(const Duration(milliseconds: 40), _navigateToApp);
      return;
    }

    if (authState.isAuthenticated) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _timer1?.cancel();
    _timer2?.cancel();
    _navigateTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ── Radial Luxury Obsidian & Royal Teal/Gold Glow ─────────────────
          AnimatedBuilder(
            animation: _pulseGlow,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.15,
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.20 * _pulseGlow.value),
                      const Color(0xFF0A1922).withValues(alpha: 0.55 * _pulseGlow.value),
                      AppTheme.background,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // ── Decorative Ambient Architectural Rings ────────────────────────
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.85,
              height: size.width * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.15,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.92,
              height: size.width * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // ── Center Brand Content ──────────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // 1. Royal Medallion Logo Badge
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF142434), Color(0xFF09121B)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.32),
                          blurRadius: 36,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.18),
                          blurRadius: 52,
                          spreadRadius: 8,
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.55),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 84,
                        height: 84,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.apartment_rounded,
                          size: 72,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // 2. Company Name
                SlideTransition(
                  position: _companySlide,
                  child: FadeTransition(
                    opacity: _companyOpacity,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Colors.white,
                              Color(0xFFE2F1EC),
                              AppTheme.accent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'BITAR HOLDING',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'SOCIMCO REAL ESTATE & DEVELOPMENT',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.4,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Subtitle Pill Badge
                SlideTransition(
                  position: _subtitleSlide,
                  child: FadeTransition(
                    opacity: _subtitleOpacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'EXECUTIVE PROPERTY SUITE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Bottom Progress & Status Indicator ───────────────────────
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _subtitleOpacity.value,
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 4,
                            child: AnimatedLinearProgressIndicator(
                              value: _progressValue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _statusText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedLinearProgressIndicator extends StatelessWidget {
  final double value;

  const AnimatedLinearProgressIndicator({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return LinearProgressIndicator(
          value: val,
          backgroundColor: AppTheme.surfaceHover,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
        );
      },
    );
  }
}
