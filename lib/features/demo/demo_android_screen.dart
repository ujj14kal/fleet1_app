import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/platform_widgets.dart';

class DemoAndroidScreen extends StatelessWidget {
  const DemoAndroidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      title: 'Fleet1 — Android',
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primaryAmber,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Text('Hello', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
          const SizedBox(height: 6),
          Text('Active shipments and fleet status', style: GoogleFonts.inter(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Card(
                color: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pending', style: GoogleFonts.inter(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Text('12', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                color: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Delivered', style: GoogleFonts.inter(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Text('48', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.supportGreen)),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: 8,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, idx) => ListTile(
                tileColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                leading: CircleAvatar(backgroundColor: AppColors.navyMid, child: Text('${idx + 1}', style: GoogleFonts.inter(color: AppColors.white))),
                title: Text('Shipment ${idx + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                subtitle: Text('Bengaluru → Chennai', style: GoogleFonts.inter(color: AppColors.textMuted)),
                trailing: Text('In transit', style: GoogleFonts.inter(color: AppColors.primaryNavy, fontWeight: FontWeight.w700)),
                onTap: () {},
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
