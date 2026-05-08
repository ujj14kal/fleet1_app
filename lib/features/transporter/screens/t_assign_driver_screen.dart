import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shipment_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/session_service.dart';
import '../../../shared/widgets/truck_loader.dart';
import '../../../shared/widgets/stat_card.dart';

class TAssignDriverTab extends StatefulWidget {
  const TAssignDriverTab({super.key});

  @override
  State<TAssignDriverTab> createState() => _TAssignDriverTabState();
}

class _TAssignDriverTabState extends State<TAssignDriverTab>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _unassigned = [];
  List<Map<String, dynamic>> _assigned = [];
  bool _loading = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await SessionService.touch();
    final profile = await AuthService.getCurrentProfile();
    if (profile == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final transporter = await Supabase.instance.client
          .from('transporters')
          .select('id')
          .eq('user_id', profile.id)
          .maybeSingle();

      if (transporter == null) {
        if (mounted) setState(() { _unassigned = []; _assigned = []; _loading = false; });
        return;
      }

      final assignments = await ShipmentService.getTransporterAssignments(
        transporter['id'] as String,
      );

      final unassigned = <Map<String, dynamic>>[];
      final assigned = <Map<String, dynamic>>[];

      for (final a in assignments) {
        final shipment = a['shipments'] as Map<String, dynamic>?;
        if (shipment == null) continue;
        final status = shipment['status']?.toString() ?? '';
        // Skip delivered/cancelled
        if (status == 'delivered' || status == 'cancelled') continue;

        final driverName = shipment['driver_name']?.toString().trim() ?? '';
        final driverPhone = shipment['driver_phone']?.toString().trim() ?? '';
        final driverId = shipment['driver_id']?.toString().trim() ?? '';

        if (driverName.isEmpty && driverPhone.isEmpty && driverId.isEmpty) {
          unassigned.add(shipment);
        } else {
          assigned.add(shipment);
        }
      }

      if (mounted) {
        setState(() {
          _unassigned = unassigned;
          _assigned = assigned;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _unassigned = []; _assigned = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: Text(
          'Assign Driver',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primaryAmber,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.primaryAmber,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: 'Unassigned (${_unassigned.length})'),
            Tab(text: 'Assigned (${_assigned.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: TruckLoader(message: 'Loading shipments...'))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _ShipmentList(
                  shipments: _unassigned,
                  showChangeButton: false,
                  onRefresh: _load,
                ),
                _ShipmentList(
                  shipments: _assigned,
                  showChangeButton: true,
                  onRefresh: _load,
                ),
              ],
            ),
    );
  }
}

class _ShipmentList extends StatelessWidget {
  final List<Map<String, dynamic>> shipments;
  final bool showChangeButton;
  final VoidCallback onRefresh;

  const _ShipmentList({
    required this.shipments,
    required this.showChangeButton,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showChangeButton ? Icons.swap_horiz_rounded : Icons.person_add_alt_1_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              showChangeButton ? 'No drivers assigned yet' : 'All shipments have drivers!',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              showChangeButton
                  ? 'Assign drivers to shipments from the Unassigned tab'
                  : 'Great! All active shipments have assigned drivers',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryAmber,
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: shipments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _ShipmentDriverCard(
          shipment: shipments[i],
          showChangeButton: showChangeButton,
          onChanged: onRefresh,
        ),
      ),
    );
  }
}

class _ShipmentDriverCard extends StatelessWidget {
  final Map<String, dynamic> shipment;
  final bool showChangeButton;
  final VoidCallback onChanged;

  const _ShipmentDriverCard({
    required this.shipment,
    required this.showChangeButton,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final code = shipment['shipment_code'] ??
        (shipment['id'] as String).substring(0, 8).toUpperCase();
    final from = shipment['pickup_city'] as String? ?? '—';
    final to = shipment['receiver_city'] as String? ?? '—';
    final driverName = shipment['driver_name']?.toString() ?? '';
    final driverPhone = shipment['driver_phone']?.toString() ?? '';
    final status = shipment['status'] as String? ?? '';
    final goods = shipment['goods_description'] as String? ?? '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(code, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w800,
                color: AppColors.primaryAmber, letterSpacing: 0.5,
              )),
              const Spacer(),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.radio_button_checked, size: 12, color: AppColors.primaryNavy),
              const SizedBox(width: 6),
              Text(from, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textMuted),
              ),
              const Icon(Icons.location_on, size: 12, color: AppColors.secondaryRed),
              const SizedBox(width: 6),
              Text(to, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(goods, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          if (showChangeButton && driverName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.greenBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.supportGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        if (driverPhone.isNotEmpty)
                          Text(driverPhone, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAssignModal(context),
              icon: Icon(
                showChangeButton ? Icons.swap_horiz_rounded : Icons.person_add_alt_1_rounded,
                size: 16,
              ),
              label: Text(showChangeButton ? 'Change Driver' : 'Assign Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: showChangeButton ? AppColors.primaryNavy : AppColors.primaryAmber,
                foregroundColor: showChangeButton ? Colors.white : AppColors.supportDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignDriverSheet(
        shipment: shipment,
        isChange: showChangeButton,
        onAssigned: onChanged,
      ),
    );
  }
}

// ── Assign Driver Bottom Sheet ────────────────────────────
class _AssignDriverSheet extends StatefulWidget {
  final Map<String, dynamic> shipment;
  final bool isChange;
  final VoidCallback onAssigned;

  const _AssignDriverSheet({
    required this.shipment,
    required this.isChange,
    required this.onAssigned,
  });

  @override
  State<_AssignDriverSheet> createState() => _AssignDriverSheetState();
}

class _AssignDriverSheetState extends State<_AssignDriverSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  List<Map<String, dynamic>> _matches = [];
  Map<String, dynamic>? _selected;
  bool _searching = false;
  bool _submitting = false;
  bool _searched = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty && phone.isEmpty) {
      setState(() => _error = 'Enter a name or phone number to search.');
      return;
    }

    setState(() {
      _searching = true;
      _searched = false;
      _matches = [];
      _selected = null;
      _error = null;
    });

    final results = await ShipmentService.searchDrivers(
      name: name.isEmpty ? null : name,
      phone: phone.isEmpty ? null : phone,
    );

    if (mounted) {
      setState(() {
        _matches = results;
        _searching = false;
        _searched = true;
        // Auto-select if only one result
        if (results.length == 1) _selected = results.first;
      });
    }
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() { _submitting = true; _error = null; });

    try {
      await ShipmentService.assignDriverToShipment(
        shipmentId: widget.shipment['id'] as String,
        driverId: _selected!['id']?.toString(),
        driverName: (_selected!['full_name'] ?? _selected!['fullName'])?.toString(),
        driverPhone: (_selected!['phone'] ?? _selected!['phoneNumber'])?.toString(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAssigned();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Driver ${_selected!['full_name'] ?? ''} assigned successfully!',
            ),
            backgroundColor: AppColors.supportGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }

  String _matchLabel(String matchType) {
    switch (matchType) {
      case 'phone': return 'Phone match';
      case 'both': return 'Name & phone match';
      default: return 'Name match';
    }
  }

  Color _matchColor(String matchType) {
    switch (matchType) {
      case 'phone': return AppColors.primaryNavy;
      case 'both': return AppColors.supportGreen;
      default: return AppColors.primaryAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.shipment['shipment_code'] ??
        (widget.shipment['id'] as String).substring(0, 8).toUpperCase();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(100)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.isChange ? 'Change Driver' : 'Assign Driver',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                code,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.primaryAmber, fontWeight: FontWeight.w700),
              ),
              if (widget.isChange) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.amberLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.amberBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primaryAmber),
                      const SizedBox(width: 6),
                      Text(
                        'Currently: ${widget.shipment['driver_name'] ?? 'Unknown'}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.primaryAmber, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Info note
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navyLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryNavy.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 14, color: AppColors.primaryNavy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search by driver name (partial match) or exact phone number. Case-insensitive.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.primaryNavy),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search fields
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Driver name (e.g. Rajesh, kumar)',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryNavy, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: const Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Phone number (exact match)',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryNavy, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textMuted),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 12),

              if (_error != null && !_searched)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondaryRed)),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _searching ? null : _search,
                  icon: _searching
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.search_rounded, size: 18),
                  label: Text(_searching ? 'Searching...' : 'Search Drivers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              // ── Search Results ─────────────────────────────
              if (_searched) ...[
                const SizedBox(height: 16),
                if (_matches.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.redLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.redBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_off_rounded, color: AppColors.secondaryRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No drivers found. Check the name/phone or ask them to register in the driver app.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondaryRed),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Text(
                        '${_matches.length} driver${_matches.length == 1 ? '' : 's'} found',
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppColors.textMuted, letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tap to select',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...(_matches.map((m) {
                    final name = (m['full_name'] ?? m['fullName'] ?? '—') as String;
                    final phone = (m['phone'] ?? '—') as String;
                    final matchType = (m['_match_type'] ?? 'name') as String;
                    final isSel = _selected != null && _selected!['id']?.toString() == m['id']?.toString();

                    return GestureDetector(
                      onTap: () => setState(() => _selected = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.navyLight : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? AppColors.primaryNavy : AppColors.border,
                            width: isSel ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primaryNavy : AppColors.border,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: GoogleFonts.inter(
                                    fontSize: 18, fontWeight: FontWeight.w800,
                                    color: isSel ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    phone,
                                    style: GoogleFonts.inter(
                                      fontSize: 12, color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Match type badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _matchColor(matchType).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      _matchLabel(matchType),
                                      style: GoogleFonts.inter(
                                        fontSize: 9, fontWeight: FontWeight.w700,
                                        color: _matchColor(matchType),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Selection indicator
                            if (isSel)
                              Container(
                                width: 26, height: 26,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryNavy,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                              ),
                          ],
                        ),
                      ),
                    );
                  })),
                ],
              ],

              // ── Selected Driver Confirm ────────────────────
              if (_selected != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.greenBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.supportGreen, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selected: ${(_selected!['full_name'] ?? '—')}  ·  ${(_selected!['phone'] ?? '—')}',
                          style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.supportGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondaryRed)),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _confirm,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _submitting
                          ? 'Assigning...'
                          : widget.isChange
                          ? 'Confirm Driver Change'
                          : 'Confirm Assignment',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.supportGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}