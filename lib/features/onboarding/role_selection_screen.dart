import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: Column(
        children: [
          // ── Hero / Top section ──────────────────────────────
          SizedBox(
            height: size.height * 0.40,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Logo + wordmark
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.25),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/images/logo_fleet1.png',
                            width: 36,
                            height: 36,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('FLEET', style: GoogleFonts.inter(
                              fontSize: 20, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 2.5,
                            )),
                            Text('1', style: GoogleFonts.inter(
                              fontSize: 20, fontWeight: FontWeight.w900,
                              color: AppColors.primaryAmber, letterSpacing: 2.5,
                            )),
                          ],
                        ),
                      ],
                    )
                    .animate().fade(duration: 500.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOut),

                    const Spacer(),

                    // Big heading
                    Text(
                      'India\'s Smartest\nB2B Logistics.',
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.18,
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate(delay: 150.ms)
                    .fade(duration: 500.ms)
                    .slideY(begin: 0.25, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 10),

                    // Subheading
                    Text(
                      'Choose your role to get started.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    )
                    .animate(delay: 250.ms)
                    .fade(duration: 500.ms),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom sheet / Cards ────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  children: [
                    // Pill handle
                    Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 28),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),

                    // Manufacturer card
                    _RoleCard(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F2F58), Color(0xFF2D4070)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      accentColor: AppColors.primaryAmber,
                      icon: Icons.factory_rounded,
                      label: 'Manufacturer',
                      tag: 'SENDER',
                      description: 'Book shipments, track deliveries\nand manage your logistics end-to-end.',
                      onTap: () => context.go('/manufacturer/login'),
                      delay: 350,
                    ),

                    const SizedBox(height: 16),

                    // Transporter card
                    _RoleCard(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7A4A00), Color(0xFFBF7800)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      accentColor: Colors.white,
                      icon: Icons.local_shipping_rounded,
                      label: 'Transporter',
                      tag: 'CARRIER',
                      description: 'Accept assignments, dispatch\ntrucks and confirm deliveries.',
                      onTap: () => context.go('/transporter/login'),
                      delay: 450,
                    ),

                    const Spacer(),

                    // Terms
                    Text(
                      'By continuing you agree to our Terms of Service & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    )
                    .animate(delay: 600.ms)
                    .fade(duration: 400.ms),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role Card ──────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final Gradient gradient;
  final Color accentColor;
  final IconData icon;
  final String label;
  final String tag;
  final String description;
  final VoidCallback onTap;
  final int delay;

  const _RoleCard({
    required this.gradient,
    required this.accentColor,
    required this.icon,
    required this.label,
    required this.tag,
    required this.description,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    HapticFeedback.lightImpact();
    _press.forward();
  }

  void _onTapUp(_) {
    _press.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _press.reverse();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),

              const SizedBox(width: 18),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.label,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            widget.tag,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.70),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    )
    .animate(delay: Duration(milliseconds: widget.delay))
    .fade(duration: 450.ms)
    .slideY(begin: 0.35, end: 0, curve: Curves.easeOutCubic);
  }
}
