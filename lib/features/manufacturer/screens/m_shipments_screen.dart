import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/shipment_model.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/shipment_service.dart';
import '../../../shared/widgets/fleet1_app_bar.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/truck_loader.dart';

class MShipmentsTab extends StatefulWidget {
  const MShipmentsTab({super.key});
  @override
  State<MShipmentsTab> createState() => _MShipmentsTabState();
}

class _MShipmentsTabState extends State<MShipmentsTab>
    with SingleTickerProviderStateMixin {
  ProfileModel? _profile;
  List<ShipmentModel> _all = [];
  List<ShipmentModel> _filtered = [];
  bool _loading = true;
  String _filterStatus = '';
  String _search = '';
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _profile = await AuthService.getCurrentProfile();
    if (_profile == null) return;
    final data = await ShipmentService.getManufacturerShipments(_profile!.id);
    if (mounted) {
      setState(() {
        _all = data;
        _loading = false;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    setState(() {
      var list = [..._all];
      if (_tabCtrl.index == 1) list = list.where((s) => s.isActive).toList();
      if (_tabCtrl.index == 2) list = list.where((s) => s.isDelivered).toList();
      if (_search.isNotEmpty) {
        list = list
            .where(
              (s) =>
                  s.displayCode.toLowerCase().contains(_search) ||
                  s.goodsDescription.toLowerCase().contains(_search) ||
                  s.pickupCity.toLowerCase().contains(_search) ||
                  s.receiverCity.toLowerCase().contains(_search),
            )
            .toList();
      }
      _filtered = list;
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
          'My Shipments',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primaryAmber,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.primaryAmber,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: 'All (${_all.length})'),
            Tab(text: 'Active (${_all.where((s) => s.isActive).length})'),
            Tab(text: 'Delivered (${_all.where((s) => s.isDelivered).length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                _search = v.toLowerCase();
                _applyFilter();
              },
              decoration: InputDecoration(
                hintText: 'Search by ID, goods, city...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(
                    child: TruckLoader(message: 'Loading shipments...'),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No shipments found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primaryAmber,
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _ShipmentListTile(shipment: _filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentListTile extends StatelessWidget {
  final ShipmentModel shipment;
  const _ShipmentListTile({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                shipment.displayCode,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryAmber,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              StatusBadge(status: shipment.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.radio_button_checked,
                size: 12,
                color: AppColors.primaryNavy,
              ),
              const SizedBox(width: 6),
              Text(
                shipment.pickupCity,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const Icon(
                Icons.location_on,
                size: 12,
                color: AppColors.secondaryRed,
              ),
              const SizedBox(width: 6),
              Text(
                shipment.receiverCity,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 12,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                shipment.goodsDescription,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.calendar_today_outlined,
                size: 11,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('d MMM').format(shipment.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
