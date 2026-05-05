import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/shipment_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/shipment_service.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/truck_loader.dart';

class MTrackingTab extends StatefulWidget {
  const MTrackingTab({super.key});
  @override
  State<MTrackingTab> createState() => _MTrackingTabState();
}

class _MTrackingTabState extends State<MTrackingTab> {
  ProfileModel? _profile;
  List<ShipmentModel> _active = [];
  ShipmentModel? _selected;
  List<StatusUpdate> _updates = [];
  bool _loading = true, _trackLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _profile = await AuthService.getCurrentProfile();
    if (_profile == null) return;
    final data = await ShipmentService.getManufacturerShipments(_profile!.id);
    if (mounted)
      setState(() {
        _active = data.where((s) => s.isActive).toList();
        _loading = false;
      });
  }

  Future<void> _track(ShipmentModel s) async {
    setState(() {
      _selected = s;
      _trackLoading = true;
    });
    final updates = await ShipmentService.getStatusUpdates(s.id);
    if (mounted)
      setState(() {
        _updates = updates;
        _trackLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: Text(
          'Live Tracking',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.supportGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.supportGreen.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.supportGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.supportGreen,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: TruckLoader(message: 'Loading tracking...'))
          : _active.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_searching_rounded,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No active shipments to track',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Shipment picker
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT SHIPMENT',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _active.map((s) {
                            final sel = _selected?.id == s.id;
                            return GestureDetector(
                              onTap: () => _track(s),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 0,
                                ),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primaryNavy
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.primaryNavy
                                        : AppColors.border,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    s.displayCode,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: sel
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _selected == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.touch_app_rounded,
                                size: 36,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap a shipment to track',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _trackLoading
                      ? const Center(
                          child: TruckLoader(message: 'Tracking shipment...'),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Shipment summary card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _selected!.displayCode,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryAmber,
                                          ),
                                        ),
                                        const Spacer(),
                                        StatusBadge(status: _selected!.status),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _TrackRow(
                                      icon: Icons.inventory_2_outlined,
                                      label: 'Goods',
                                      value: _selected!.goodsDescription,
                                    ),
                                    _TrackRow(
                                      icon: Icons.route_outlined,
                                      label: 'Route',
                                      value:
                                          '${_selected!.pickupCity} → ${_selected!.receiverCity}',
                                    ),
                                    _TrackRow(
                                      icon: Icons.person_outline_rounded,
                                      label: 'Receiver',
                                      value: _selected!.receiverName,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (_selected!.loadTypeRequired == 'full_load') ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.map_rounded, color: AppColors.primaryAmber, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'LIVE MAP',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textMuted,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        height: 140,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppColors.navyLight,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Map tracking will be enabled once a driver is assigned.',
                                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Timeline
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'TRACK HISTORY',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMuted,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${_updates.length} updates',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (_updates.isEmpty)
                                      Text(
                                        'No status updates yet',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      )
                                    else
                                      ..._updates.reversed.map(
                                        (u) => _TimelineEntry(update: u),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _TrackRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TimelineEntry extends StatelessWidget {
  final StatusUpdate update;
  const _TimelineEntry({required this.update});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.supportGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
            Container(width: 1.5, height: 30, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                update.status.replaceAll('_', ' ').toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              if (update.city != null)
                Text(
                  update.city!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (update.note != null)
                Text(
                  update.note!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              Text(
                DateFormat(
                  'd MMM yyyy, hh:mm a',
                ).format(update.createdAt.toLocal()),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
