import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
// Tab screens exported here for router
export 'screens/m_home_screen.dart';
export 'screens/m_shipments_screen.dart';
export 'screens/m_create_shipment_screen.dart';
export 'screens/m_tracking_screen.dart';
export 'screens/m_profile_screen.dart';

class MShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MShell({super.key, required this.shell});

  static const _tabs = [
    _TabItem(icon: Icons.dashboard_rounded,       label: 'Home'),
    _TabItem(icon: Icons.inventory_2_rounded,     label: 'Shipments'),
    _TabItem(icon: Icons.add_circle_rounded,      label: 'Book'),
    _TabItem(icon: Icons.location_on_rounded,     label: 'Track'),
    _TabItem(icon: Icons.person_rounded,          label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _Fleet1BottomNav(
        currentIndex: shell.currentIndex,
        tabs: _tabs,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class TShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const TShell({super.key, required this.shell});

  static const _tabs = [
    _TabItem(icon: Icons.dashboard_rounded,       label: 'Home'),
    _TabItem(icon: Icons.inventory_rounded,       label: 'Assigned'),
    _TabItem(icon: Icons.swap_horiz_rounded,      label: 'Handover'),
    _TabItem(icon: Icons.local_shipping_rounded,  label: 'Fleet'),
    _TabItem(icon: Icons.person_rounded,          label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _Fleet1BottomNav(
        currentIndex: shell.currentIndex,
        tabs: _tabs,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────
class _Fleet1BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _Fleet1BottomNav({required this.currentIndex, required this.tabs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.amberLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Icon(
                          tabs[i].icon,
                          color: selected ? AppColors.primaryNavy : AppColors.textMuted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(tabs[i].label,
                        style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppColors.primaryNavy : AppColors.textMuted,
                        )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}
