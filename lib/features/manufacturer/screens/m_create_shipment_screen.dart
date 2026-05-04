import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/shipment_service.dart';
import '../../../shared/widgets/fleet1_app_bar.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

const _allCities = [
  'Agra','Ahmedabad','Ajmer','Amritsar','Bengaluru','Bhopal','Chandigarh','Chennai',
  'Coimbatore','Dehradun','Delhi','Gurgaon','Guwahati','Hyderabad','Indore','Jaipur',
  'Jodhpur','Kanpur','Kochi','Kolkata','Lucknow','Ludhiana','Mumbai','Nagpur','Nashik',
  'Noida','Patna','Pune','Raipur','Rajkot','Surat','Vadodara','Varanasi','Visakhapatnam',
];

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
  String? _pickupCity, _receiverCity, _loadType;
  bool _loading = false;
  String? _success, _error;

  @override
  void dispose() {
    _goodsCtrl.dispose(); _qtyCtrl.dispose(); _weightCtrl.dispose();
    _rNameCtrl.dispose(); _rPhoneCtrl.dispose(); _rAddrCtrl.dispose(); _rPincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_goodsCtrl.text.trim().isEmpty || _pickupCity == null || _receiverCity == null ||
        _rNameCtrl.text.trim().isEmpty || _rPhoneCtrl.text.trim().isEmpty || _loadType == null) {
      setState(() => _error = 'Please fill in all required fields including load type.');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });

    final profile = await AuthService.getCurrentProfile();
    if (profile == null || !mounted) return;

    try {
      await ShipmentService.createShipment({
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
        'status': 'pending',
      });
      if (mounted) {
        setState(() { _loading = false; _success = 'Shipment created successfully! Our ops team will assign a transporter shortly.'; });
        _goodsCtrl.clear(); _qtyCtrl.clear(); _weightCtrl.clear();
        _rNameCtrl.clear(); _rPhoneCtrl.clear(); _rAddrCtrl.clear(); _rPincodeCtrl.clear();
        setState(() { _pickupCity = null; _receiverCity = null; _loadType = null; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy, elevation: 0,
        title: Text('New Shipment', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Load type selector
          _SectionLabel('Load Type *'),
          Row(children: [
            for (final lt in [
              {'id': 'part_load', 'label': 'Part Load', 'icon': '📦'},
              {'id': 'full_load', 'label': 'Full Truck', 'icon': '🚛'},
            ]) ...[
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _loadType = lt['id'] as String),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _loadType == lt['id'] ? AppColors.amberLight : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _loadType == lt['id'] ? AppColors.primaryAmber : AppColors.border, width: _loadType == lt['id'] ? 2 : 1),
                  ),
                  child: Column(children: [
                    Text(lt['icon'] as String, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 6),
                    Text(lt['label'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ]),
                ),
              )),
              const SizedBox(width: 12),
            ],
          ]),

          const SizedBox(height: 24),
          _SectionLabel('Shipment Details'),
          Fleet1TextField(label: 'Goods Description *', hint: 'e.g. Electronic Components, Textile Goods', controller: _goodsCtrl, prefixIcon: Icons.inventory_2_outlined),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Fleet1TextField(label: 'Quantity (units)', hint: '100', controller: _qtyCtrl, keyboardType: TextInputType.number, prefixIcon: Icons.numbers_rounded)),
            const SizedBox(width: 12),
            Expanded(child: Fleet1TextField(label: 'Weight (kg)', hint: '500', controller: _weightCtrl, keyboardType: TextInputType.number, prefixIcon: Icons.scale_outlined)),
          ]),

          const SizedBox(height: 24),
          _SectionLabel('Route'),
          _CityDropdown(label: 'Pickup City *', value: _pickupCity, icon: Icons.radio_button_checked, onChanged: (v) => setState(() => _pickupCity = v)),
          const SizedBox(height: 14),
          _CityDropdown(label: 'Delivery City *', value: _receiverCity, icon: Icons.location_on, iconColor: AppColors.secondaryRed, onChanged: (v) => setState(() => _receiverCity = v)),

          const SizedBox(height: 24),
          _SectionLabel('Receiver Details'),
          Fleet1TextField(label: 'Receiver Name *', hint: 'Amit Sharma', controller: _rNameCtrl, prefixIcon: Icons.person_outline_rounded),
          const SizedBox(height: 14),
          Fleet1TextField(label: 'Receiver Phone *', hint: '9876543210', controller: _rPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, prefixIcon: Icons.phone_outlined),
          const SizedBox(height: 14),
          Fleet1TextField(label: 'Delivery Address *', hint: 'Plot 23, Sector 5, Industrial Area', controller: _rAddrCtrl, prefixIcon: Icons.home_outlined),
          const SizedBox(height: 14),
          Fleet1TextField(label: 'Pincode', hint: '110001', controller: _rPincodeCtrl, keyboardType: TextInputType.number, prefixIcon: Icons.pin_drop_outlined),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.redBorder)),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.secondaryRed, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondaryRed))),
              ])),
          ],
          if (_success != null) ...[
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.greenBorder)),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.supportGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_success!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.supportGreen))),
              ])),
          ],

          const SizedBox(height: 28),
          PrimaryButton(label: 'Create Shipment', onTap: _submit, loading: _loading, icon: Icons.send_rounded),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8)),
  );
}

class _CityDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Color? iconColor;
  final ValueChanged<String?> onChanged;

  const _CityDropdown({required this.label, this.value, required this.icon, this.iconColor, required this.onChanged});

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
