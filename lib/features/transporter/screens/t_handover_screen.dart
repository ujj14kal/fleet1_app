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

class THandoverTab extends StatefulWidget {
  const THandoverTab({super.key});
  @override
  State<THandoverTab> createState() => _THandoverTabState();
}

class _THandoverTabState extends State<THandoverTab> with SingleTickerProviderStateMixin {
  ProfileModel? _profile;
  TransporterModel? _transporter;
  List<Map<String, dynamic>> _handovers = [];
  bool _loading = true;
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    _profile = await AuthService.getCurrentProfile();
    if (_profile == null) return;
    final trpData = await Supabase.instance.client.from('transporters').select().eq('user_id', _profile!.id).maybeSingle();
    if (trpData != null) _transporter = TransporterModel.fromJson(trpData);
    if (_transporter != null) {
      final data = await ShipmentService.getHandovers(_transporter!.id);
      if (mounted) setState(() { _handovers = data; _loading = false; });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateHandoverSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _CreateHandoverSheet(
        transporter: _transporter!,
        onCreated: () { Navigator.pop(context); _load(); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final received = _handovers.where((h) => h['to_transporter_id'] == _transporter?.id).toList();
    final given    = _handovers.where((h) => h['from_transporter_id'] == _transporter?.id).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy, elevation: 0,
        title: Text('Handover Management', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: _transporter == null ? null : () => _showCreateHandoverSheet(context),
            tooltip: 'Create Handover',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primaryAmber, unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.primaryAmber, indicatorWeight: 2.5,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: [Tab(text: 'Received (${received.length})'), Tab(text: 'Given (${given.length})')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAmber))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _HandoverList(handovers: received, isReceived: true),
                _HandoverList(handovers: given,    isReceived: false),
              ],
            ),
      floatingActionButton: _transporter != null
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateHandoverSheet(context),
              backgroundColor: AppColors.primaryAmber, foregroundColor: AppColors.supportDark,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text('Initiate Handover', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}

class _HandoverList extends StatelessWidget {
  final List<Map<String, dynamic>> handovers;
  final bool isReceived;
  const _HandoverList({required this.handovers, required this.isReceived});

  @override
  Widget build(BuildContext context) {
    if (handovers.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(isReceived ? Icons.inbox_rounded : Icons.outbox_rounded, size: 48, color: AppColors.textMuted),
      const SizedBox(height: 12),
      Text(isReceived ? 'No handovers received' : 'No handovers given',
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: handovers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final h = handovers[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isReceived ? AppColors.greenLight : AppColors.amberLight, borderRadius: BorderRadius.circular(8)),
                child: Icon(isReceived ? Icons.call_received_rounded : Icons.call_made_rounded, size: 14, color: isReceived ? AppColors.supportGreen : AppColors.primaryAmber)),
              const SizedBox(width: 10),
              Text(isReceived ? 'RECEIVED FROM' : 'HANDED TO', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                color: isReceived ? AppColors.supportGreen : AppColors.primaryAmber)),
              const Spacer(),
              Text(DateFormat('d MMM').format(DateTime.parse(h['created_at'] as String)), style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 10),
            if (h['handover_location'] != null) ...[
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(h['handover_location'] as String, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 6),
            ],
            if (h['goods_condition'] != null) Row(children: [
              const Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('Condition: ${h['goods_condition']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ]),
            if (h['remarks'] != null && (h['remarks'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(h['remarks'] as String, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            ],
          ]),
        );
      },
    );
  }
}

class _CreateHandoverSheet extends StatefulWidget {
  final TransporterModel transporter;
  final VoidCallback onCreated;
  const _CreateHandoverSheet({required this.transporter, required this.onCreated});
  @override
  State<_CreateHandoverSheet> createState() => _CreateHandoverSheetState();
}

class _CreateHandoverSheetState extends State<_CreateHandoverSheet> {
  String? _selectedShipmentId;
  String? _selectedToTransporterId;
  final _locationCtrl   = TextEditingController();
  final _conditionCtrl  = TextEditingController();
  final _remarksCtrl    = TextEditingController();
  List<Map<String, dynamic>> _activeShipments = [];
  List<Map<String, dynamic>> _allTransporters  = [];
  bool _loading = true, _submitting = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final asgn = await ShipmentService.getTransporterAssignments(widget.transporter.id);
    final trps = await ShipmentService.getAllTransporters();
    final activeShipments = asgn.map((a) => a['shipments'] as Map<String,dynamic>?).where((s) => s != null && s['status'] != 'delivered').map((s) => s!).toList();
    if (mounted) setState(() { _activeShipments = activeShipments; _allTransporters = trps.where((t) => t['id'] != widget.transporter.id).toList(); _loading = false; });
  }

  Future<void> _submit() async {
    if (_selectedShipmentId == null || _selectedToTransporterId == null) return;
    setState(() => _submitting = true);
    await ShipmentService.createHandover(
      shipmentId: _selectedShipmentId!,
      fromTransporterId: widget.transporter.id,
      toTransporterId: _selectedToTransporterId!,
      handoverLocation: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      goodsCondition: _conditionCtrl.text.trim().isEmpty ? null : _conditionCtrl.text.trim(),
      remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
    );
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.primaryAmber)))
            : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(100)))),
                const SizedBox(height: 20),
                Text('Create Handover', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Transfer a shipment to another transporter', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 20),
                _DropLabel('Shipment *'),
                DropdownButtonFormField<String>(value: _selectedShipmentId, onChanged: (v) => setState(() => _selectedShipmentId = v),
                  decoration: _dropDecor(), hint: Text('Select shipment', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                  items: _activeShipments.map((s) => DropdownMenuItem(value: s['id'] as String,
                    child: Text(s['shipment_code'] ?? s['id'].toString().substring(0,8)))).toList()),
                const SizedBox(height: 14),
                _DropLabel('Handover To (Transporter) *'),
                DropdownButtonFormField<String>(value: _selectedToTransporterId, onChanged: (v) => setState(() => _selectedToTransporterId = v),
                  decoration: _dropDecor(), hint: Text('Select transporter', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                  items: _allTransporters.map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['company_name'] as String? ?? '—'))).toList()),
                const SizedBox(height: 14),
                TextField(controller: _locationCtrl, decoration: _textDecor('Handover Location (optional)', Icons.location_on_outlined)),
                const SizedBox(height: 10),
                TextField(controller: _conditionCtrl, decoration: _textDecor('Goods Condition (optional)', Icons.inventory_2_outlined)),
                const SizedBox(height: 10),
                TextField(controller: _remarksCtrl, decoration: _textDecor('Remarks (optional)', Icons.notes_rounded)),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Confirm Handover', onTap: _selectedShipmentId == null || _selectedToTransporterId == null ? null : _submit, loading: _submitting, icon: Icons.swap_horiz_rounded),
              ]),
      ),
    );
  }

  Widget _DropLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)));

  InputDecoration _dropDecor() => InputDecoration(filled: true, fillColor: AppColors.background,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14));

  InputDecoration _textDecor(String hint, IconData icon) => InputDecoration(hintText: hint, filled: true, fillColor: AppColors.background,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted));
}
