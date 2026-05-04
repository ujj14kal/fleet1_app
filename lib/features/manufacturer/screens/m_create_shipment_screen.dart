import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/shipment_service.dart';
import '../../../shared/widgets/fleet1_app_bar.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/constants/truck_catalogue.dart';

const _allCities = [
  'Agra','Ahmedabad','Ajmer','Amritsar','Bengaluru','Bhopal','Chandigarh','Chennai',
  'Coimbatore','Dehradun','Delhi','Gurgaon','Guwahati','Hyderabad','Indore','Jaipur',
  'Jodhpur','Kanpur','Kochi','Kolkata','Lucknow','Ludhiana','Mumbai','Nagpur','Nashik',
  'Noida','Patna','Pune','Raipur','Rajkot','Surat','Vadodara','Varanasi','Visakhapatnam',
];
const _prefsKey = 'fleet1_saved_addresses';

class SavedAddress {
  final String name, phone, address, city, pincode;
  SavedAddress({required this.name,required this.phone,required this.address,required this.city,required this.pincode});
  factory SavedAddress.fromJson(Map<String,dynamic> j) => SavedAddress(name:j['name']??'',phone:j['phone']??'',address:j['address']??'',city:j['city']??'',pincode:j['pincode']??'');
  Map<String,dynamic> toJson() => {'name':name,'phone':phone,'address':address,'city':city,'pincode':pincode};
}

class MCreateTab extends StatefulWidget {
  const MCreateTab({super.key});
  @override
  State<MCreateTab> createState() => _MCreateTabState();
}

class _MCreateTabState extends State<MCreateTab> {
  final _goodsCtrl    = TextEditingController();
  final _qtyCtrl      = TextEditingController();
  final _weightCtrl   = TextEditingController();
  final _rNameCtrl    = TextEditingController();
  final _rPhoneCtrl   = TextEditingController();
  final _rAddrCtrl    = TextEditingController();
  final _rPincodeCtrl = TextEditingController();

  String? _pickupCity, _receiverCity, _loadType, _selectedTruckId;
  bool _loading = false, _saveAddress = false, _loadingTrucks = false;
  String? _error;
  List<SavedAddress> _savedAddresses = [];
  List<Map<String,dynamic>> _availableTrucks = []; // from Supabase

  @override
  void initState() { super.initState(); _loadSavedAddresses(); }

  @override
  void dispose() {
    _goodsCtrl.dispose(); _qtyCtrl.dispose(); _weightCtrl.dispose();
    _rNameCtrl.dispose(); _rPhoneCtrl.dispose(); _rAddrCtrl.dispose(); _rPincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    if (mounted) setState(() => _savedAddresses = raw.map((s) => SavedAddress.fromJson(jsonDecode(s))).toList());
  }

  Future<void> _persistAddress(SavedAddress a) async {
    final prefs = await SharedPreferences.getInstance();
    final list = ([a, ..._savedAddresses]).take(5).toList();
    await prefs.setStringList(_prefsKey, list.map((x) => jsonEncode(x.toJson())).toList());
    setState(() => _savedAddresses = list);
  }

  void _applySaved(SavedAddress a) => setState(() {
    _rNameCtrl.text = a.name; _rPhoneCtrl.text = a.phone;
    _rAddrCtrl.text = a.address; _receiverCity = a.city; _rPincodeCtrl.text = a.pincode;
  });

  /// Called whenever weight changes or load type changes — fetches & filters truck list.
  Future<void> _refreshTrucks() async {
    if (_loadType != 'full_load') { setState(() { _availableTrucks = []; _selectedTruckId = null; }); return; }
    final wt = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    if (wt <= 0) { setState(() => _availableTrucks = []); return; }

    setState(() { _loadingTrucks = true; _selectedTruckId = null; });

    // 1. Try Supabase first (real registered trucks)
    var trucks = await ShipmentService.getAvailableTrucksByCapacity(wt);

    // 2. Fallback: use local catalogue (all FTL trucks, include overloaded ones greyed)
    if (trucks.isEmpty) {
      trucks = kTruckCatalogue
          .where((t) => t['cat'] == 'full_load')
          .map((t) => {'truck_type': t['id'], 'truck_label': t['name'], 'capacity_kg': t['cap_kg']})
          .toList();
    }

    // Sort: can-handle first, overloaded last
    trucks.sort((a, b) {
      final aOk = (a['capacity_kg'] as int) >= wt.toInt() ? 0 : 1;
      final bOk = (b['capacity_kg'] as int) >= wt.toInt() ? 0 : 1;
      if (aOk != bOk) return aOk.compareTo(bOk);
      return (a['capacity_kg'] as int).compareTo(b['capacity_kg'] as int);
    });

    if (mounted) setState(() { _availableTrucks = trucks; _loadingTrucks = false; });
  }

  Future<void> _submit() async {
    if (_goodsCtrl.text.trim().isEmpty || _pickupCity == null || _receiverCity == null ||
        _rNameCtrl.text.trim().isEmpty || _rPhoneCtrl.text.trim().isEmpty || _loadType == null) {
      setState(() => _error = 'Please fill in all required fields.'); return;
    }
    if (_loadType == 'full_load' && _selectedTruckId == null) {
      setState(() => _error = 'Please select a truck type for full truck booking.'); return;
    }
    setState(() { _loading = true; _error = null; });
    final profile = await AuthService.getCurrentProfile();
    if (profile == null || !mounted) return;
    try {
      final result = await ShipmentService.createShipment({
        'manufacturer_id': profile.id,
        'goods_description': _goodsCtrl.text.trim(),
        'quantity': int.tryParse(_qtyCtrl.text.trim()),
        'weight': double.tryParse(_weightCtrl.text.trim()),
        'pickup_city': _pickupCity,
        'receiver_name': _rNameCtrl.text.trim(),
        'receiver_phone': _rPhoneCtrl.text.trim(),
        'receiver_address': _rAddrCtrl.text.trim(),
        'receiver_city': _receiverCity,
        'receiver_pincode': _rPincodeCtrl.text.trim(),
        'load_type_required': _loadType,
        'truck_type_preferred': _selectedTruckId,
        'status': 'pending',
      });
      if (_saveAddress && _rNameCtrl.text.isNotEmpty) {
        await _persistAddress(SavedAddress(name:_rNameCtrl.text.trim(),phone:_rPhoneCtrl.text.trim(),address:_rAddrCtrl.text.trim(),city:_receiverCity!,pincode:_rPincodeCtrl.text.trim()));
      }
      if (!mounted) return;
      context.go('/m/confirm', extra: {
        'code': result?.displayCode ?? 'SHP-NEW',
        'pickupCity': _pickupCity!,
        'deliveryCity': _receiverCity!,
        'goods': _goodsCtrl.text.trim(),
        'loadType': _loadType!,
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wt = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: Fleet1AppBar(title: 'New Shipment', onBack: () => context.go('/m/home')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Load Type ─────────────────────────────────────
          _Label('Load Type *'),
          Row(children: [
            for (final lt in [
              {'id':'part_load','label':'Part Load (PTL)','icon':'📦','desc':'Share truck space'},
              {'id':'full_load','label':'Full Truck (FTL)','icon':'🚛','desc':'Entire truck booked'},
            ]) Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () { setState(() { _loadType = lt['id'] as String; _selectedTruckId = null; }); _refreshTrucks(); },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _loadType == lt['id'] ? (_loadType == 'full_load' ? AppColors.amberLight : AppColors.navyLight) : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _loadType == lt['id'] ? (_loadType == 'full_load' ? AppColors.primaryAmber : AppColors.primaryNavy) : AppColors.border,
                      width: _loadType == lt['id'] ? 2 : 1,
                    ),
                  ),
                  child: Column(children: [
                    Text(lt['icon'] as String, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(lt['label'] as String, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary), textAlign: TextAlign.center),
                    Text(lt['desc'] as String, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
                  ]),
                ),
              ),
            )),
          ]),

          const SizedBox(height: 24),
          _Label('Shipment Details'),
          Fleet1TextField(label:'Goods Description *',hint:'e.g. Electronic Components',controller:_goodsCtrl,prefixIcon:Icons.inventory_2_outlined),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Fleet1TextField(label:'Quantity',hint:'100',controller:_qtyCtrl,keyboardType:TextInputType.number,prefixIcon:Icons.numbers_rounded)),
            const SizedBox(width: 12),
            Expanded(child: Fleet1TextField(
              label:'Weight (kg)',hint:'500',controller:_weightCtrl,
              keyboardType:TextInputType.number,prefixIcon:Icons.scale_outlined,
              onChanged: (_) => _refreshTrucks(),
            )),
          ]),

          // ── FTL Truck Selection ───────────────────────────
          if (_loadType == 'full_load') ...[
            const SizedBox(height: 24),
            Row(children: [
              const Icon(Icons.local_shipping_rounded, color: AppColors.primaryAmber, size: 16),
              const SizedBox(width: 6),
              Text('Select Truck Type *', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 6),
            if (wt <= 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  const Icon(Icons.scale_outlined, color: AppColors.textMuted, size: 28),
                  const SizedBox(width: 14),
                  Expanded(child: Text('Enter weight above to see available trucks', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
                ]),
              )
            else if (_loadingTrucks)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primaryAmber)))
            else
              _TruckGrid(
                trucks: _availableTrucks,
                weightKg: wt,
                selectedId: _selectedTruckId,
                onSelect: (id) => setState(() => _selectedTruckId = id),
              ),
          ],

          const SizedBox(height: 24),
          _Label('Route'),
          _CityDrop(label:'Pickup City *',value:_pickupCity,icon:Icons.radio_button_checked,onChanged:(v)=>setState(()=>_pickupCity=v)),
          const SizedBox(height: 14),
          _CityDrop(label:'Delivery City *',value:_receiverCity,icon:Icons.location_on,iconColor:AppColors.secondaryRed,onChanged:(v)=>setState(()=>_receiverCity=v)),

          const SizedBox(height: 24),
          Row(children: [
            Text('RECEIVER DETAILS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8)),
            const Spacer(),
            if (_savedAddresses.isNotEmpty)
              GestureDetector(
                onTap: () => _showSavedSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.bookmark_rounded, size: 13, color: AppColors.primaryNavy),
                    const SizedBox(width: 4),
                    Text('Saved (${_savedAddresses.length})', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Fleet1TextField(label:'Receiver Name *',hint:'Amit Sharma',controller:_rNameCtrl,prefixIcon:Icons.person_outline_rounded),
          const SizedBox(height: 14),
          Fleet1TextField(label:'Receiver Phone *',hint:'9876543210',controller:_rPhoneCtrl,keyboardType:TextInputType.phone,maxLength:10,prefixIcon:Icons.phone_outlined),
          const SizedBox(height: 14),
          Fleet1TextField(label:'Delivery Address',hint:'Plot 23, Sector 5',controller:_rAddrCtrl,prefixIcon:Icons.home_outlined),
          const SizedBox(height: 14),
          _CityDrop(label:'Receiver City *',value:_receiverCity,icon:Icons.location_city_outlined,onChanged:(v)=>setState(()=>_receiverCity=v)),
          const SizedBox(height: 14),
          Fleet1TextField(label:'Pincode',hint:'110001',controller:_rPincodeCtrl,keyboardType:TextInputType.number,prefixIcon:Icons.pin_drop_outlined),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _saveAddress = !_saveAddress),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: _saveAddress ? AppColors.primaryNavy : Colors.white,
                  border: Border.all(color: _saveAddress ? AppColors.primaryNavy : AppColors.border, width: 2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: _saveAddress ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
              ),
              const SizedBox(width: 10),
              Text('Save this receiver address', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.redBorder)),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.secondaryRed, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondaryRed))),
              ])),
          ],

          const SizedBox(height: 28),
          PrimaryButton(label: 'Create Shipment', onTap: _submit, loading: _loading, icon: Icons.send_rounded),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  void _showSavedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(100)))),
          const SizedBox(height: 16),
          Text('Saved Addresses', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ..._savedAddresses.map((a) => GestureDetector(
            onTap: () { Navigator.pop(context); _applySaved(a); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                const Icon(Icons.person_pin_outlined, color: AppColors.primaryNavy, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('${a.city}  ·  ${a.phone}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                ])),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ]),
            ),
          )),
        ]),
      ),
    );
  }
}

// ── Truck Grid ─────────────────────────────────────────────
class _TruckGrid extends StatelessWidget {
  final List<Map<String,dynamic>> trucks;
  final double weightKg;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  const _TruckGrid({required this.trucks, required this.weightKg, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (trucks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 28),
          const SizedBox(width: 14),
          Expanded(child: Text('No trucks found for ${weightKg.toStringAsFixed(0)} kg', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
        ]),
      );
    }

    final hasOverloaded = trucks.any((t) => (t['capacity_kg'] as int) < weightKg.toInt());

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${trucks.length} truck types available for ${weightKg.toStringAsFixed(0)} kg',
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
      if (hasOverloaded) ...[
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.redBorder)),
          child: Row(children: [
            const Icon(Icons.warning_rounded, color: AppColors.secondaryRed, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text('Red trucks are overloaded for this weight and cannot be selected.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondaryRed))),
          ]),
        ),
      ],
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.3, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: trucks.length,
        itemBuilder: (_, i) {
          final t = trucks[i];
          final type = t['truck_type'] as String? ?? '';
          final label = t['truck_label'] as String? ?? type;
          final capKg = t['capacity_kg'] as int? ?? 0;
          final isOverloaded = capKg < weightKg.toInt();
          final isSelected = selectedId == type;
          final pct = weightKg > 0 ? ((weightKg / capKg) * 100).round() : 0;
          final img = truckImage(type);

          return GestureDetector(
            onTap: isOverloaded ? () {
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('This truck is overloaded for ${weightKg.toStringAsFixed(0)} kg'),
                backgroundColor: AppColors.secondaryRed, duration: const Duration(seconds: 2),
              ));
            } : () => onSelect(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOverloaded ? AppColors.redLight : isSelected ? AppColors.amberLight : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isOverloaded ? AppColors.redBorder : isSelected ? AppColors.primaryAmber : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(children: [
                if (isSelected)
                  Align(alignment: Alignment.topRight, child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(color: AppColors.primaryAmber, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                  ))
                else
                  const SizedBox(height: 18),
                Expanded(child: Image.asset(img, fit: BoxFit.contain,
                  errorBuilder: (_,__,___) => const Icon(Icons.local_shipping_rounded, color: AppColors.textMuted, size: 32))),
                const SizedBox(height: 4),
                Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Up to ${capKg.toStringAsFixed(0)} kg',
                  style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted)),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOverloaded ? AppColors.secondaryRed.withValues(alpha: 0.12) : AppColors.supportGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    isOverloaded ? 'Overloaded ($pct%)' : '$pct% loaded',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                      color: isOverloaded ? AppColors.secondaryRed : AppColors.supportGreen),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    ]);
  }
}

// ── Small helpers ─────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8)),
  );
}

class _CityDrop extends StatelessWidget {
  final String label; final String? value; final IconData icon; final Color? iconColor; final ValueChanged<String?> onChanged;
  const _CityDrop({required this.label, this.value, required this.icon, this.iconColor, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    const SizedBox(height: 6),
    DropdownButtonFormField<String>(
      value: value, onChanged: onChanged,
      decoration: InputDecoration(
        filled: true, fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryNavy, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: Icon(icon, color: iconColor ?? AppColors.textMuted, size: 18),
      ),
      hint: Text('Select city', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
      items: _allCities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 13)))).toList(),
    ),
  ]);
}
