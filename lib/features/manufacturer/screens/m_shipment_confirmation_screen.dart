import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

/// Interactive shipment confirmation screen shown immediately after booking.
class ShipmentConfirmationScreen extends StatelessWidget {
  final String shipmentCode;
  final String pickupCity;
  final String deliveryCity;
  final String goodsDescription;
  final String loadType;

  const ShipmentConfirmationScreen({
    super.key,
    required this.shipmentCode,
    required this.pickupCity,
    required this.deliveryCity,
    required this.goodsDescription,
    required this.loadType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top navy section ────────────────────────────
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated check circle
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.supportGreen.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.supportGreen, width: 2.5),
                    ),
                    child: const Icon(Icons.check_rounded, color: AppColors.supportGreen, size: 44),
                  )
                  .animate()
                  .scale(begin: const Offset(0.2, 0.2), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut)
                  .fade(duration: 300.ms),

                  const SizedBox(height: 20),

                  Text(
                    'Shipment Booked!',
                    style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                  )
                  .animate(delay: 300.ms)
                  .fade(duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'Our team will assign a transporter shortly.',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  )
                  .animate(delay: 450.ms)
                  .fade(duration: 400.ms),

                  const SizedBox(height: 24),

                  // Shipment code badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAmber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shipmentCode,
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.supportDark, letterSpacing: 1),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: shipmentCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Shipment code copied!'), duration: Duration(seconds: 1)),
                            );
                          },
                          child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.supportDark),
                        ),
                      ],
                    ),
                  )
                  .animate(delay: 550.ms)
                  .fade(duration: 400.ms)
                  .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1)),
                ],
              ),
            ),

            // ── White details card ───────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  // Route row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _RouteStop(city: pickupCity, color: AppColors.primaryNavy, icon: Icons.radio_button_checked),
                        Expanded(
                          child: Column(children: [
                            const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted, size: 18),
                            Text('Direct Route', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted)),
                          ]),
                        ),
                        _RouteStop(city: deliveryCity, color: AppColors.secondaryRed, icon: Icons.location_on_rounded),
                      ],
                    ),
                  )
                  .animate(delay: 650.ms).fade(duration: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  // Details row
                  Row(
                    children: [
                      _DetailChip(label: 'Goods', value: goodsDescription),
                      const SizedBox(width: 10),
                      _DetailChip(
                        label: 'Load Type',
                        value: loadType == 'full_load' ? 'Full Truck' : 'Part Load',
                      ),
                    ],
                  )
                  .animate(delay: 700.ms).fade(duration: 400.ms),

                  const SizedBox(height: 12),

                  // Tracking note
                  if (loadType == 'full_load')
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.amberBorder),
                      ),
                      child: Row(children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primaryAmber, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          'Live map tracking will be available once a driver is assigned.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.primaryAmber, fontWeight: FontWeight.w500),
                        )),
                      ]),
                    )
                    .animate(delay: 750.ms).fade(duration: 400.ms),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/m/create'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryNavy),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Book Another', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go('/m/home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text('Dashboard', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                  .animate(delay: 800.ms).fade(duration: 400.ms).slideY(begin: 0.3, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  final String city;
  final Color color;
  final IconData icon;
  const _RouteStop({required this.city, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(city, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ],
  );
}

class _DetailChip extends StatelessWidget {
  final String label, value;
  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8)),
        const SizedBox(height: 3),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}
