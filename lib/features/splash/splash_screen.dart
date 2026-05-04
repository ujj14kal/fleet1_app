import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _navigate();
  }

  Future<void> _navigate() async {
    // Wait for animations (2.8s total)
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final valid = await SessionService.isSessionValid();
    if (valid) {
      final profile = await AuthService.getCurrentProfile();
      if (profile != null && mounted) {
        switch (profile.role) {
          case 'manufacturer': context.go('/m/home'); return;
          case 'transporter':  context.go('/t/home'); return;
          default: context.go('/role'); return;
        }
      }
    }
    if (mounted) context.go('/role');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ──────────────────────────────────────────
            Image.asset(
              'assets/images/logo_fleet1.png',
              width: 100,
              height: 100,
            )
            .animate()
            .scale(
              begin: const Offset(0.3, 0.3),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
            .fade(begin: 0, end: 1, duration: 300.ms),

            const SizedBox(height: 20),

            // FLEET1 wordmark ────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'FLEET',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    letterSpacing: 3,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  '1',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryAmber,
                    letterSpacing: 3,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            )
            .animate(delay: 400.ms)
            .fade(begin: 0, end: 1, duration: 500.ms)
            .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut),

            const SizedBox(height: 8),

            // Tagline ─────────────────────────────────────────
            Text(
              "India's Smartest B2B Logistics",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.55),
                letterSpacing: 0.5,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            )
            .animate(delay: 700.ms)
            .fade(begin: 0, end: 1, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

