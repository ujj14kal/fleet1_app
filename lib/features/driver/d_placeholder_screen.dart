import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class DPlaceholderScreen extends StatelessWidget {
  const DPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go('/role'),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.drive_eta_rounded, color: AppColors.supportGreen, size: 48),
                    ),
                    const SizedBox(height: 24),
                    Text('Driver App', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      'Coming Soon',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.supportGreen),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The Fleet1 Driver app with live GPS tracking,\nOTP delivery confirmation, and turn-by-turn\nrouting is on its way.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(children: [
                        _FeatureRow(icon: Icons.location_on_rounded, color: AppColors.supportGreen, label: 'Real-time GPS tracking'),
                        _FeatureRow(icon: Icons.pin_rounded,         color: AppColors.primaryAmber,  label: 'OTP-based delivery confirmation'),
                        _FeatureRow(icon: Icons.visibility_rounded,  color: AppColors.primaryNavy,   label: 'Live location to manufacturer & receiver'),
                        _FeatureRow(icon: Icons.route_rounded,       color: Color(0xFF8B5CF6),       label: 'Turn-by-turn routing', last: true),
                      ]),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Text('Tap back to return to role selection', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon; final Color color; final String label; final bool last;
  const _FeatureRow({required this.icon, required this.color, required this.label, this.last = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 14),
    child: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16)),
      const SizedBox(width: 12),
      Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
    ]),
  );
}
