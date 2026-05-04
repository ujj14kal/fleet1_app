import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/fleet1_app_bar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

// Truck catalogue constant (matches web platform)
const _truckCatalogue = [
  {'id': 'tata_ace_7ft',   'name': 'Tata Ace • 7ft',     'cap': '750 kg',    'cap_kg': 750,   'category': 'part_load', 'img': 'assets/images/truck_mini.png'},
  {'id': 'bolero_8ft',     'name': 'Bolero • 8ft',        'cap': '1,000 kg',  'cap_kg': 1000,  'category': 'part_load', 'img': 'assets/images/truck_mini.png'},
  {'id': 'open_10ft',      'name': 'Open • 10ft',         'cap': '2,000 kg',  'cap_kg': 2000,  'category': 'part_load', 'img': 'assets/images/truck_mini.png'},
  {'id': 'open_14ft',      'name': 'Open • 14ft',         'cap': '4,000 kg',  'cap_kg': 4000,  'category': 'part_load', 'img': 'assets/images/truck_large.png'},
  {'id': 'open_17ft',      'name': 'Open • 17ft',         'cap': '7,000 kg',  'cap_kg': 7000,  'category': 'full_load', 'img': 'assets/images/truck_large.png'},
  {'id': 'open_20ft',      'name': 'Open • 20ft',         'cap': '10,000 kg', 'cap_kg': 10000, 'category': 'full_load', 'img': 'assets/images/truck_large.png'},
  {'id': 'container_14ft', 'name': 'Container • 14ft',    'cap': '5,000 kg',  'cap_kg': 5000,  'category': 'full_load', 'img': 'assets/images/truck_container.png'},
  {'id': 'container_20ft', 'name': 'Container • 20ft',    'cap': '10,000 kg', 'cap_kg': 10000, 'category': 'full_load', 'img': 'assets/images/truck_container.png'},
  {'id': 'container_32ft', 'name': 'Container • 32ft',    'cap': '20,000 kg', 'cap_kg': 20000, 'category': 'full_load', 'img': 'assets/images/truck_container.png'},
  {'id': 'trailer_20ft',   'name': 'Trailer • 20ft',      'cap': '15,000 kg', 'cap_kg': 15000, 'category': 'full_load', 'img': 'assets/images/truck_trailer.png'},
  {'id': 'trailer_32ft',   'name': 'Trailer • 32ft',      'cap': '30,000 kg', 'cap_kg': 30000, 'category': 'full_load', 'img': 'assets/images/truck_trailer.png'},
];

const _allCities = [
  'Agra','Ahmedabad','Ajmer','Amritsar','Bengaluru','Bhopal','Chandigarh','Chennai',
  'Coimbatore','Dehradun','Delhi','Gurgaon','Guwahati','Hyderabad','Indore','Jaipur',
  'Jodhpur','Kanpur','Kochi','Kolkata','Lucknow','Ludhiana','Mumbai','Nagpur','Nashik',
  'Noida','Patna','Pune','Raipur','Rajkot','Surat','Vadodara','Varanasi','Visakhapatnam',
];

class TSignupScreen extends StatefulWidget {
  const TSignupScreen({super.key});
  @override
  State<TSignupScreen> createState() => _TSignupScreenState();
}

class _TSignupScreenState extends State<TSignupScreen> {
  int _step = 0; // 0=basic, 1=load type, 2=routes, 3=trucks
  final _nameCtrl    = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  String? _selectedLoadType;
  String? _operatingFrom;
  final Set<String> _operatingCities = {};
  final Set<String> _selectedTrucks  = {};
  bool _loading = false, _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _companyCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final trucks = _truckCatalogue.where((t) => _selectedTrucks.contains(t['id'])).map((t) => {
      'truck_label': t['name'], 'truck_type': t['id'],
      'load_category': t['category'], 'capacity_kg': t['cap_kg'],
      'truck_number': null, 'driver_name': null, 'driver_phone': null,
    }).toList();

    final res = await AuthService.signUpTransporter(
      email: _emailCtrl.text.trim(), password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(), companyName: _companyCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(), operatingFrom: _operatingFrom!,
      operatingCities: _operatingCities.toList(), loadType: _selectedLoadType!,
      trucks: trucks,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.isSuccess) {
      context.go('/t/home');
    } else {
      setState(() => _error = res.error);
    }
  }

  bool _validateStep() {
    setState(() => _error = null);
    switch (_step) {
      case 0:
        if (_nameCtrl.text.trim().isEmpty || _companyCtrl.text.trim().isEmpty ||
            _emailCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty ||
            _passCtrl.text.isEmpty) {
          setState(() => _error = 'Please fill in all fields.'); return false;
        }
        if (_phoneCtrl.text.trim().length != 10) {
          setState(() => _error = 'Phone must be 10 digits.'); return false;
        }
        final passRegex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,}$');
        if (!passRegex.hasMatch(_passCtrl.text)) {
          setState(() => _error = 'Password must be 8+ chars with uppercase, number & special char.'); return false;
        }
        return true;
      case 1:
        if (_selectedLoadType == null) { setState(() => _error = 'Please select a load type.'); return false; }
        return true;
      case 2:
        if (_operatingFrom == null) { setState(() => _error = 'Please select your base city.'); return false; }
        if (_operatingCities.isEmpty) { setState(() => _error = 'Please select at least one operating city.'); return false; }
        return true;
      case 3:
        if (_selectedTrucks.isEmpty) { setState(() => _error = 'Please select at least one truck.'); return false; }
        return true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: Fleet1AppBar(
        title: 'Join the Network',
        onBack: _step > 0 ? () => setState(() { _step--; _error = null; }) : () => context.go('/transporter/login'),
      ),
      body: Column(
        children: [
          // Progress bar
          _StepProgress(current: _step, total: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildStep(),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.redBorder)),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.secondaryRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondaryRed))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: _step == 3 ? 'Create Account & Join' : 'Continue →',
                    onTap: () {
                      if (_validateStep()) {
                        if (_step < 3) { setState(() => _step++); }
                        else { _submit(); }
                      }
                    },
                    loading: _loading && _step == 3,
                    icon: _step == 3 ? Icons.check_circle_outline_rounded : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      case 3: return _buildStep4();
      default: return const SizedBox();
    }
  }

  Widget _buildStep1() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Basic Information', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
    const SizedBox(height: 4),
    Text('Tell us about you and your company', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
    const SizedBox(height: 24),
    Fleet1TextField(label: 'Contact Person Name', hint: 'Rajesh Kumar', controller: _nameCtrl, prefixIcon: Icons.person_outline_rounded),
    const SizedBox(height: 16),
    Fleet1TextField(label: 'Company Name', hint: 'Fast Freight Pvt. Ltd.', controller: _companyCtrl, prefixIcon: Icons.business_outlined),
    const SizedBox(height: 16),
    Fleet1TextField(label: 'Email Address', hint: 'rajesh@fastfreight.com', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
    const SizedBox(height: 16),
    Fleet1TextField(label: 'Phone Number', hint: '9876543210', controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, prefixIcon: Icons.phone_outlined),
    const SizedBox(height: 16),
    Fleet1TextField(label: 'Password', hint: '••••••••', controller: _passCtrl, obscureText: _obscure, prefixIcon: Icons.lock_outline_rounded, suffixIcon: _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, onSuffixTap: () => setState(() => _obscure = !_obscure)),
    const SizedBox(height: 6),
    Text('Min 8 chars · 1 uppercase · 1 number · 1 special character', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
  ]);

  Widget _buildStep2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Load Type', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
    const SizedBox(height: 4),
    Text('What kind of loads do you carry?', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
    const SizedBox(height: 24),
    for (final lt in [
      {'id': 'part_load', 'icon': '📦', 'label': 'Part Load', 'desc': 'Shared truck space — smaller shipments'},
      {'id': 'full_load', 'icon': '🚛', 'label': 'Full Load', 'desc': 'Entire truck booked for one shipment'},
      {'id': 'both',      'icon': '⚡', 'label': 'Both',       'desc': 'Accept both part & full load shipments'},
    ]) ...[
      GestureDetector(
        onTap: () => setState(() => _selectedLoadType = lt['id'] as String),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedLoadType == lt['id'] ? AppColors.amberLight : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _selectedLoadType == lt['id'] ? AppColors.primaryAmber : AppColors.border, width: _selectedLoadType == lt['id'] ? 2 : 1),
          ),
          child: Row(children: [
            Text(lt['icon'] as String, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lt['label'] as String, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(lt['desc'] as String, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            if (_selectedLoadType == lt['id'])
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryAmber),
          ]),
        ),
      ),
    ],
  ]);

  Widget _buildStep3() {
    final allSelected = _operatingCities.length == _allCities.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Operating Routes', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text('Where do you operate from and deliver to?', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      Text('Base City (Pick-up city)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _operatingFrom,
        onChanged: (v) => setState(() => _operatingFrom = v),
        decoration: InputDecoration(
          filled: true, fillColor: AppColors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted),
        ),
        hint: Text('Select your base city', style: GoogleFonts.inter(color: AppColors.textMuted)),
        items: _allCities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      ),
      const SizedBox(height: 20),
      Text('Operating Cities (Delivery destinations)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 10),

      // ── All India toggle ────────────────────────────────
      GestureDetector(
        onTap: () => setState(() {
          if (allSelected) {
            _operatingCities.clear();
          } else {
            _operatingCities.addAll(_allCities);
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: allSelected
                ? const LinearGradient(colors: [Color(0xFF1F2F58), Color(0xFF2D4070)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: allSelected ? null : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: allSelected ? AppColors.primaryNavy : AppColors.border,
              width: allSelected ? 0 : 1,
            ),
            boxShadow: allSelected ? [BoxShadow(color: AppColors.primaryNavy.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Row(children: [
            Text('🇮🇳', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('All India', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: allSelected ? Colors.white : AppColors.textPrimary)),
              Text(allSelected ? 'All ${_allCities.length} cities selected' : 'Operate across all of India — select all cities',
                style: GoogleFonts.inter(fontSize: 12, color: allSelected ? Colors.white.withValues(alpha: 0.75) : AppColors.textSecondary)),
            ])),
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: allSelected ? AppColors.primaryAmber : AppColors.border,
              ),
              child: Icon(allSelected ? Icons.check_rounded : Icons.add_rounded, color: Colors.white, size: 14),
            ),
          ]),
        ),
      ),

      const SizedBox(height: 14),
      Text('Or pick individual cities:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _allCities.map((city) {
          final sel = _operatingCities.contains(city);
          return GestureDetector(
            onTap: () => setState(() => sel ? _operatingCities.remove(city) : _operatingCities.add(city)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? AppColors.amberLight : AppColors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: sel ? AppColors.primaryAmber : AppColors.border),
              ),
              child: Text(city, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                color: sel ? AppColors.primaryAmber : AppColors.textSecondary)),
            ),
          );
        }).toList(),
      ),
      if (_operatingCities.isNotEmpty && !allSelected) ...[
        const SizedBox(height: 10),
        Text('${_operatingCities.length} cities selected', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryAmber)),
      ],
    ]);
  }

  Widget _buildStep4() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Your Fleet', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
    const SizedBox(height: 4),
    Text('Select all trucks you own and operate', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
    const SizedBox(height: 24),
    GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.45, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: _truckCatalogue.length,
      itemBuilder: (_, i) {
        final t = _truckCatalogue[i];
        final id = t['id'] as String;
        final sel = _selectedTrucks.contains(id);
        return GestureDetector(
          onTap: () => setState(() => sel ? _selectedTrucks.remove(id) : _selectedTrucks.add(id)),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: sel ? AppColors.amberLight : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? AppColors.primaryAmber : AppColors.border, width: sel ? 2 : 1),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(
                child: Image.asset(
                  t['img'] as String,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.local_shipping_rounded,
                    color: sel ? AppColors.primaryAmber : AppColors.textMuted, size: 28),
                ),
              ),
              const SizedBox(height: 4),
              Text(t['name'] as String, textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(t['cap'] as String, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: t['category'] == 'part_load' ? AppColors.navyLight : AppColors.greenLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(t['category'] == 'part_load' ? 'Part' : 'Full',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                    color: t['category'] == 'part_load' ? AppColors.primaryNavy : AppColors.supportGreen)),
              ),
            ]),
          ),
        );
      },
    ),
    if (_selectedTrucks.isNotEmpty) ...[
      const SizedBox(height: 12),
      Text('${_selectedTrucks.length} truck(s) selected', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryAmber)),
    ],
  ]);
}

class _StepProgress extends StatelessWidget {
  final int current, total;
  const _StepProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final labels = ['Basic Info', 'Load Type', 'Routes', 'Fleet'];
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: List.generate(total * 2 - 1, (i) {
          if (i.isOdd) {
            final idx = i ~/ 2;
            return Expanded(child: Container(height: 2, color: idx < current ? AppColors.primaryAmber : AppColors.border));
          }
          final idx = i ~/ 2;
          final done = idx < current;
          final active = idx == current;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primaryAmber : active ? AppColors.primaryNavy : AppColors.border,
              ),
              child: Center(child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : Text('${idx + 1}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textMuted))),
            ),
            const SizedBox(height: 4),
            Text(labels[idx], style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: active ? AppColors.primaryNavy : AppColors.textMuted)),
          ]);
        }),
      ),
    );
  }
}
