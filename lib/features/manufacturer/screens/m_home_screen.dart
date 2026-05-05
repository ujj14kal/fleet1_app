import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/shipment_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/shipment_service.dart';
import '../../../core/services/session_service.dart';
import '../../../shared/widgets/fleet1_app_bar.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/truck_loader.dart';

class MHomeTab extends StatefulWidget {
  const MHomeTab({super.key});
  @override
  State<MHomeTab> createState() => _MHomeTabState();
}

class _MHomeTabState extends State<MHomeTab> {
  ProfileModel? _profile;
  List<ShipmentModel> _shipments = [];
  bool _loading = true;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _startClock();
    _load();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  Future<void> _load() async {
    await SessionService.touch();
    _profile = await AuthService.getCurrentProfile();
    if (_profile == null && mounted) {
      context.go('/role');
      return;
    }
    final data = await ShipmentService.getManufacturerShipments(_profile!.id);
    if (mounted)
      setState(() {
        _shipments = data;
        _loading = false;
      });
  }

  String _greeting() {
    final h = _now.hour;
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.fullName?.split(' ').first ?? '';
    final active = _shipments.where((s) => s.isActive).length;
    final inTransit = _shipments
        .where(
          (s) => [
            'arrived_at_hub',
            'in_transit_to_receiver',
            'in_transit_to_transporter',
          ].contains(s.status),
        )
        .length;
    final delivered = _shipments.where((s) => s.isDelivered).length;
    final pending = _shipments.where((s) => s.status == 'pending').length;
    final recent = _shipments.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryAmber,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.primaryNavy,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_greeting()}, ${name.isEmpty ? "there" : name} 👋',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, d MMMM yyyy').format(_now),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Avatar
                        GestureDetector(
                          onTap: () => context.go('/m/profile'),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primaryAmber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _profile?.initials ?? '--',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.supportDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Quick book buttons
                    Row(
                      children: [
                        Expanded(
                          child: _QuickBookBtn(
                            label: 'Create Shipment',
                            icon: Icons.add_box_rounded,
                            onTap: () => context.go('/m/create?type=part_load'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickBookBtn(
                            label: 'Book Full Truck',
                            icon: Icons.local_shipping_rounded,
                            onTap: () => context.go('/m/create?type=full_load'),
                            amber: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        value: '$active',
                        label: 'Active Shipments',
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.primaryAmber,
                      ),
                      StatCard(
                        value: '$inTransit',
                        label: 'In Transit',
                        icon: Icons.local_shipping_rounded,
                        color: Color(0xFF8B5CF6),
                      ),
                      StatCard(
                        value: '$delivered',
                        label: 'Delivered',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.supportGreen,
                      ),
                      StatCard(
                        value: '$pending',
                        label: 'Pending Assignment',
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.secondaryRed,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  // Recent shipments
                  Row(
                    children: [
                      Text(
                        'RECENT SHIPMENTS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go('/m/shipments'),
                        child: Text(
                          'See all',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: TruckLoader(message: 'Fetching shipments...'),
                      ),
                    )
                  else if (recent.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.textMuted,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No shipments yet',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Create your first shipment to get started',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SecondaryButton(
                            label: 'Create Shipment',
                            onTap: () => context.go('/m/create'),
                            icon: Icons.add_rounded,
                          ),
                        ],
                      ),
                    )
                  else
                    ...recent.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ShipmentCard(
                          shipment: s.toJson(),
                          onTap: () => _showShipmentDetail(context, s),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShipmentDetail(BuildContext context, ShipmentModel s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShipmentDetailSheet(shipment: s),
    );
  }
}

extension on ShipmentModel {
  Map<String, dynamic> toJson() => {
    'id': id,
    'shipment_code': shipmentCode,
    'pickup_city': pickupCity,
    'receiver_city': receiverCity,
    'goods_description': goodsDescription,
    'quantity': quantity,
    'weight': weight,
    'status': status,
    'load_type_required': loadTypeRequired,
    'truck_type_required': truckTypeRequired,
  };
}

// ── Quick Book Button ─────────────────────────────────────
class _QuickBookBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool amber;

  const _QuickBookBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.amber = true,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: amber
            ? AppColors.primaryAmber
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: amber ? AppColors.supportDark : Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: amber ? AppColors.supportDark : Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Shipment Detail Bottom Sheet ──────────────────────────
class _ShipmentDetailSheet extends StatelessWidget {
  final ShipmentModel shipment;
  const _ShipmentDetailSheet({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    shipment.displayCode,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryAmber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusBadge(status: shipment.status),
                  if (shipment.loadTypeRequired != null) ...[
                    const SizedBox(width: 6),
                    LoadTypeBadge(loadType: shipment.loadTypeRequired!),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${shipment.pickupCity} → ${shipment.receiverCity}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.divider, height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      label: 'Goods',
                      value: shipment.goodsDescription,
                    ),
                    _DetailRow(
                      label: 'Quantity',
                      value: shipment.quantity != null
                          ? '${shipment.quantity} units'
                          : '—',
                    ),
                    _DetailRow(
                      label: 'Weight',
                      value: shipment.weight != null
                          ? '${shipment.weight} kg'
                          : '—',
                    ),
                    _DetailRow(
                      label: 'Load Type',
                      value: shipment.loadTypeFullLabel,
                    ),
                    if (shipment.truckTypeRequired != null)
                      _DetailRow(
                        label: 'Truck Required',
                        value: shipment.truckTypeLabel,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'RECEIVER',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(label: 'Name', value: shipment.receiverName),
                    _DetailRow(label: 'Phone', value: shipment.receiverPhone),
                    _DetailRow(label: 'City', value: shipment.receiverCity),
                    if (shipment.receiverAddress != null)
                      _DetailRow(
                        label: 'Address',
                        value: shipment.receiverAddress!,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'TIMELINE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TimelineItem(
                      label: 'Shipment Created',
                      date: shipment.createdAt,
                      done: true,
                    ),
                    _TimelineItem(
                      label: 'Status: ${shipment.status.replaceAll("_", " ")}',
                      date: shipment.updatedAt ?? shipment.createdAt,
                      done: shipment.isDelivered,
                      active: !shipment.isDelivered,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 90,
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

class _TimelineItem extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool done;
  final bool active;
  const _TimelineItem({
    required this.label,
    required this.date,
    this.done = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? AppColors.supportGreen
                  : active
                  ? AppColors.primaryAmber
                  : AppColors.border,
            ),
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : null,
          ),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              DateFormat('d MMM, hh:mm a').format(date.toLocal()),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ],
  );
}
