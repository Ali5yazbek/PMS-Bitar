// ─── Executive Brand Splash Screen ───────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  String _statusText = 'Establishing secure session...';
  double _progressValue = 0.25;
  Timer? _timer1;
  Timer? _timer2;
  Timer? _navigateTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleIn = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    _timer1 = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _statusText = 'Loading workspace configuration...';
          _progressValue = 0.72;
        });
      }
    });

    _timer2 = Timer(const Duration(milliseconds: 240), () {
      if (mounted) {
        setState(() {
          _statusText = 'Ready';
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
      final user = authState.user;
      final target = getDefaultRouteForRole(user?.role);
      context.go(target);
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleIn,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Brand Medallion
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.borderLight,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.apartment_rounded,
                      size: 48,
                      color: AppTheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'BITAR HOLDING',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.0,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'SOCIMCO REAL ESTATE & DEVELOPMENT',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                    color: AppTheme.textMuted,
                  ),
                ),

                const Spacer(flex: 3),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 3,
                          child: AnimatedLinearProgressIndicator(
                            value: _progressValue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusText,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
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
      duration: const Duration(milliseconds: 280),
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
