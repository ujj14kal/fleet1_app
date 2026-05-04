import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

// ── Status Badge ─────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  static const _statusMap = {
    'pending':                   {'label': 'Pending',                    'color': 0xFFFFa800},
    'assigned':                  {'label': 'Assigned',                   'color': 0xFF3B82F6},
    'picked_up':                 {'label': 'Picked Up',                  'color': 0xFFFFa800},
    'picked_up_by_ops':          {'label': 'Picked Up by Ops',           'color': 0xFFFFa800},
    'in_transit':                {'label': 'In Transit',                 'color': 0xFF8B5CF6},
    'in_transit_to_transporter': {'label': 'In Transit to Trp.',         'color': 0xFF8B5CF6},
    'in_transit_to_receiver':    {'label': 'In Transit to Rcvr.',        'color': 0xFF8B5CF6},
    'at_hub':                    {'label': 'At Hub',                     'color': 0xFF3B82F6},
    'arrived_at_hub':            {'label': 'Arrived at Hub',             'color': 0xFF3B82F6},
    'handover':                  {'label': 'Handover',                   'color': 0xFFFFa800},
    'handed_to_transporter':     {'label': 'Handed to Transporter',      'color': 0xFF00BF63},
    'delivered':                 {'label': 'Delivered',                  'color': 0xFF00BF63},
    'cancelled':                 {'label': 'Cancelled',                  'color': 0xFFAF0000},
  };

  @override
  Widget build(BuildContext context) {
    final meta = _statusMap[status];
    final label = meta != null ? meta['label'] as String : status.replaceAll('_', ' ').toUpperCase();
    final colorVal = meta != null ? meta['color'] as int : 0xFF94A3B8;
    final color = Color(colorVal);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2),
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const StatCard({super.key, required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Shipment Card ─────────────────────────────────────────
class ShipmentCard extends StatelessWidget {
  final Map<String, dynamic> shipment;
  final VoidCallback? onTap;

  const ShipmentCard({super.key, required this.shipment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final code   = shipment['shipment_code'] ?? (shipment['id'] as String).substring(0, 8).toUpperCase();
    final status = shipment['status'] as String? ?? 'pending';
    final from   = shipment['pickup_city'] as String? ?? '—';
    final to     = shipment['receiver_city'] as String? ?? '—';
    final goods  = shipment['goods_description'] as String? ?? '—';
    final qty    = shipment['quantity'];
    final wt     = shipment['weight'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(code, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryAmber, letterSpacing: 0.5)),
              const Spacer(),
              StatusBadge(status: status),
            ]),
            const SizedBox(height: 10),
            // Route
            Row(children: [
              const Icon(Icons.radio_button_checked, color: AppColors.primaryNavy, size: 14),
              const SizedBox(width: 6),
              Text(from, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: List.generate(4, (_) => Container(width: 4, height: 1.5, color: AppColors.border, margin: const EdgeInsets.only(right: 3)))),
              ),
              const Icon(Icons.location_on, color: AppColors.secondaryRed, size: 14),
              const SizedBox(width: 6),
              Text(to, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _InfoChip(label: goods, icon: Icons.inventory_2_outlined)),
              if (qty != null) _InfoChip(label: '$qty units', icon: Icons.numbers_rounded),
              if (wt != null) _InfoChip(label: '${wt}kg', icon: Icons.scale_outlined),
            ]),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: AppColors.textMuted),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
    const SizedBox(width: 12),
  ]);
}

// ── Section Header ────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8)),
      const Spacer(),
      if (action != null && onAction != null)
        GestureDetector(onTap: onAction, child: Text(action!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryNavy))),
    ]),
  );
}

// ── Empty State ───────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.navyLight, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primaryNavy, size: 32),
        ),
        const SizedBox(height: 16),
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
        if (action != null) ...[const SizedBox(height: 20), action!],
      ]),
    ),
  );
}

// ── Loading Shimmer placeholder ───────────────────────────
class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 110,
    decoration: BoxDecoration(
      color: AppColors.border.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
    ),
  );
}
