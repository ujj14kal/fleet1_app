import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

// ── Reusable App Bar ──────────────────────────────────────
class Fleet1AppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const Fleet1AppBar({super.key, required this.title, this.onBack, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaryNavy,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: onBack,
            )
          : null,
      title: Text(title, style: GoogleFonts.inter(
        fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white,
      )),
      actions: actions,
    );
  }
}

// ── Dashboard App Bar with user avatar ───────────────────
class Fleet1DashAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final String initials;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;

  const Fleet1DashAppBar({
    super.key, required this.title, required this.subtitle,
    required this.initials, this.onAvatarTap, this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryNavy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 20, right: 16, bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
            ]),
          ),
          GestureDetector(
            onTap: onNotificationTap,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryAmber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(initials, style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.supportDark,
              ))),
            ),
          ),
        ],
      ),
    );
  }
}
