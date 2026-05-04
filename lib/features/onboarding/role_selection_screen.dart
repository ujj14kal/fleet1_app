import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Header ────────────────────────────────────────
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo_fleet1.png',
                    width: 44,
                    height: 44,
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Text('FLEET', style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.w900,
                        color: AppColors.primaryNavy, letterSpacing: 2,
                      )),
                      Text('1', style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.w900,
                        color: AppColors.primaryAmber, letterSpacing: 2,
                      )),
                    ],
                  ),
                ],
              ).animate().fade(duration: 400.ms).slideY(begin: -0.3, end: 0),

              const SizedBox(height: 48),

              Text(
                'Welcome to\nFleet1',
                style: GoogleFonts.inter(
                  fontSize: 34, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary, height: 1.15,
                ),
              ).animate(delay: 100.ms).fade(duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),
              Text(
                'India\'s smartest B2B logistics platform.\nChoose how you use Fleet1.',
                style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5,
                ),
              ).animate(delay: 200.ms).fade(duration: 400.ms),

              const SizedBox(height: 40),

              // Role cards ─────────────────────────────────────
              _RoleCard(
                icon: Icons.factory_rounded,
                iconBg: AppColors.navyLight,
                iconColor: AppColors.primaryNavy,
                title: 'Manufacturer',
                subtitle: 'Book & track shipments\nfor your goods',
                tag: 'SENDER',
                tagColor: AppColors.primaryNavy,
                onTap: () => context.go('/manufacturer/login'),
                delay: 300,
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.local_shipping_rounded,
                iconBg: AppColors.amberLight,
                iconColor: AppColors.primaryAmber,
                title: 'Transporter',
                subtitle: 'Manage assignments\n& deliver shipments',
                tag: 'CARRIER',
                tagColor: AppColors.primaryAmber,
                onTap: () => context.go('/transporter/login'),
                delay: 400,
              ),


              const Spacer(),
              Center(
                child: Text(
                  'By continuing you agree to our Terms of Service',
                  style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textMuted,
                  ),
                ).animate(delay: 600.ms).fade(duration: 400.ms),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle, tag;
  final Color tagColor;
  final VoidCallback onTap;
  final int delay;
  final bool comingSoon;

  const _RoleCard({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, required this.tag,
    required this.tagColor, required this.onTap, required this.delay,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: comingSoon ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                      )),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(tag, style: GoogleFonts.inter(
                          fontSize: 9, fontWeight: FontWeight.w800, color: tagColor,
                          letterSpacing: 0.8,
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textMuted, height: 1.4,
                  )),
                ],
              ),
            ),
            Icon(
              comingSoon ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
              color: comingSoon ? AppColors.textMuted : AppColors.primaryNavy,
              size: 16,
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: delay)).fade(duration: 400.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOut);
  }
}
