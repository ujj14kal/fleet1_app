import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/platform_widgets.dart';

class DemoIosScreen extends StatelessWidget {
  const DemoIosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      title: 'Fleet1 — iOS',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Welcome back', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.supportDark)),
            const SizedBox(height: 8),
            Text('Deliveries and shipments at a glance', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 18)]),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(12))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Shipment #F11234', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
                      const SizedBox(height: 6),
                      Text('Pickup: Bengaluru • Delivery: Mumbai', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                    ]),
                  ),
                  Icon(CupertinoIcons.chevron_forward, color: AppColors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, idx) => Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: AppColors.navyMid, child: Text('${idx + 1}', style: GoogleFonts.inter(color: AppColors.white))),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Order ${idx + 1} — Electronics', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                    Text('Active', style: GoogleFonts.inter(color: AppColors.supportGreen, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
