import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/transporter_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/shipment_service.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/primary_button.dart';

class TAssignedTab extends StatefulWidget {
  const TAssignedTab({super.key});
  @override
  State<TAssignedTab> createState() => _TAssignedTabState();
}

class _TAssignedTabState extends State<TAssignedTab> {
  ProfileModel? _profile;
  TransporterModel? _transporter;
  List<Map<String, dynamic>> _assignments = [];
  bool _loading = true;
  String? _updating;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    _profile = await AuthService.getCurrentProfile();
    if (_profile == null) return;
    final trpData = await Supabase.instance.client.from('transporters').select().eq('user_id', _profile!.id).maybeSingle();
    if (trpData != null) _transporter = TransporterModel.fromJson(trpData);
    if (_transporter != null) {
      final data = await ShipmentService.getTransporterAssignments(_transporter!.id);
      if (mounted) setState(() { _assignments = data; _loading = false; });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String shipmentId, String status, String? city, String? note) async {
    setState(() => _updating = shipmentId);
    await ShipmentService.updateShipmentStatus(
      shipmentId: shipmentId, status: status, updatedBy: _profile!.id, note: note, city: city,
    );
    await _load();
    setState(() => _updating = null);
  }

  void _showStatusModal(BuildContext context, Map<String, dynamic> shipment) {
    final statuses = [
      {'id': 'picked_up',              'label': 'Picked Up',           'color': AppColors.primaryAmber},
      {'id': 'in_transit_to_receiver', 'label': 'In Transit',          'color': Color(0xFF8B5CF6)},
      {'id': 'arrived_at_hub',         'label': 'Arrived at Hub',      'color': Color(0xFF3B82F6)},
      {'id': 'delivered',              'label': 'Delivered',           'color': AppColors.supportGreen},
    ];
    final cityCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? selectedStatus;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(100)))),
            const SizedBox(height: 20),
            Text('Update Shipment Status', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(shipment['shipment_code'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primaryAmber, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, children: statuses.map((s) {
              final color = s['color'] as Color;
              final sel = selectedStatus == s['id'] as String;
              return GestureDetector(
                onTap: () => setModal(() => selectedStatus = s['id'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? color.withValues(alpha: 0.15) : AppColors.background,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: sel ? color : AppColors.border, width: sel ? 2 : 1),
                  ),
                  child: Text(s['label'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? color : AppColors.textSecondary)),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
            TextField(controller: cityCtrl, decoration: InputDecoration(hintText: 'Current city/location (optional)', filled: true, fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textMuted))),
            const SizedBox(height: 10),
            TextField(controller: noteCtrl, decoration: InputDecoration(hintText: 'Notes (optional)', filled: true, fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13))),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Update Status',
              onTap: selectedStatus == null ? null : () {
                Navigator.pop(ctx);
                _updateStatus(shipment['id'] as String, selectedStatus!, cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim(), noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
              },
              icon: Icons.check_rounded,
            ),
          ]),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipments = _assignments.map((a) => a['shipments'] as Map<String,dynamic>?).where((s) => s != null).map((s) => s!).toList();
    final active = shipments.where((s) => s['status'] != 'delivered').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy, elevation: 0,
        title: Text('Assigned Shipments', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          Container(margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: AppColors.primaryAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)),
            child: Text('${active.length} Active', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryAmber))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAmber))
          : shipments.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('No assignments yet', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ]))
              : RefreshIndicator(
                  color: AppColors.primaryAmber,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: shipments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final s = shipments[i];
                      final isUpdating = _updating == s['id'];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(s['shipment_code'] ?? (s['id'] as String).substring(0,8).toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryAmber, letterSpacing: 0.5)),
                            const Spacer(),
                            StatusBadge(status: s['status'] as String? ?? 'assigned'),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            const Icon(Icons.radio_button_checked, size: 12, color: AppColors.primaryNavy),
                            const SizedBox(width: 6),
                            Text(s['pickup_city'] as String? ?? '—', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textMuted)),
                            const Icon(Icons.location_on, size: 12, color: AppColors.secondaryRed),
                            const SizedBox(width: 6),
                            Text(s['receiver_city'] as String? ?? '—', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Expanded(child: Text(s['goods_description'] as String? ?? '—', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted))),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            if (s['quantity'] != null) _InfoPill('${s['quantity']} units'),
                            if (s['weight'] != null) _InfoPill('${s['weight']} kg'),
                            if (s['load_type_required'] != null) _InfoPill(s['load_type_required'] == 'part_load' ? 'Part Load' : 'Full Load'),
                            const Spacer(),
                            SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                onPressed: isUpdating ? null : () => _showStatusModal(context, s),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryAmber, foregroundColor: AppColors.supportDark,
                                  elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: isUpdating
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.supportDark))
                                    : Text('Update Status', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  const _InfoPill(this.label);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(100)),
    child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
  );
}
