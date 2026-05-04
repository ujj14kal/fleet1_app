import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/transporter_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/shipment_service.dart';
import '../../../core/services/session_service.dart';
import '../../../shared/widgets/stat_card.dart';

class THomeTab extends StatefulWidget {
  const THomeTab({super.key});
  @override
  State<THomeTab> createState() => _THomeTabState();
}

class _THomeTabState extends State<THomeTab> {
  ProfileModel? _profile;
  TransporterModel? _transporter;
  List<Map<String, dynamic>> _assignments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    await SessionService.touch();
    _profile = await AuthService.getCurrentProfile();
    if (_profile == null && mounted) { context.go('/role'); return; }

    final trpData = await Supabase.instance.client
        .from('transporters').select().eq('user_id', _profile!.id).maybeSingle();
    if (trpData != null) _transporter = TransporterModel.fromJson(trpData);

    if (_transporter != null) {
      final asgn = await ShipmentService.getTransporterAssignments(_transporter!.id);
      if (mounted) setState(() { _assignments = asgn; _loading = false; });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipments = _assignments
        .map((a) => a['shipments'] as Map<String, dynamic>?)
        .where((s) => s != null)
        .map((s) => s!)
        .toList();
    final active    = shipments.where((s) => s['status'] != 'delivered').length;
    final inTransit = shipments.where((s) => ['arrived_at_hub', 'in_transit_to_receiver', 'in_transit_to_transporter'].contains(s['status'])).length;
    final delivered = shipments.where((s) => s['status'] == 'delivered').length;

    final firstName = _profile?.fullName?.split(' ').first ?? '';
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryAmber,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.primaryNavy,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20, right: 20, bottom: 24,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$greeting, ${firstName.isEmpty ? "there" : firstName} 👋',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                    ])),
                    GestureDetector(
                      onTap: () => context.go('/t/profile'),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: AppColors.primaryAmber, borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(_profile?.initials ?? '--',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.supportDark))),
                      ),
                    ),
                  ]),
                  if (_transporter != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        _BannerChip(label: _transporter!.loadTypeLabel, icon: Icons.local_shipping_rounded),
                        const SizedBox(width: 16),
                        _BannerChip(label: _transporter!.operatingFrom ?? '—', icon: Icons.location_on_rounded),
                        const Spacer(),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.supportGreen, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('ACTIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.supportGreen, letterSpacing: 0.8)),
                      ]),
                    ),
                  ],
                ]),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
                    children: [
                      StatCard(value: '${_assignments.length}', label: 'Total Assigned',   icon: Icons.inventory_rounded,     color: AppColors.primaryAmber),
                      StatCard(value: '$inTransit',             label: 'In Transit',       icon: Icons.local_shipping_rounded, color: const Color(0xFF8B5CF6)),
                      StatCard(value: '$delivered',             label: 'Delivered',        icon: Icons.check_circle_rounded,  color: AppColors.supportGreen),
                      StatCard(value: '$active',                label: 'Active Now',       icon: Icons.inventory_2_rounded,   color: AppColors.primaryNavy),
                    ],
                  ),

                  const SizedBox(height: 28),
                  Row(children: [
                    Text('RECENT ASSIGNMENTS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.go('/t/assigned'),
                      child: Text('See all', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Center(child: CircularProgressIndicator(color: AppColors.primaryAmber))
                  else if (shipments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(children: [
                        const Icon(Icons.inbox_rounded, color: AppColors.textMuted, size: 36),
                        const SizedBox(height: 12),
                        Text('No assignments yet', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Text('Our ops team will assign shipments matching your routes', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
                      ]),
                    )
                  else
                    ...shipments.take(3).map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShipmentCard(shipment: s),
                    )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _BannerChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: Colors.white70, size: 12),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70)),
  ]);
}
