import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MProfileTab extends StatefulWidget {
  const MProfileTab({super.key});
  @override
  State<MProfileTab> createState() => _MProfileTabState();
}

class _MProfileTabState extends State<MProfileTab> {
  ProfileModel? _profile;
  final _nameCtrl    = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _stateCtrl   = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _streetCtrl  = TextEditingController();
  bool _loading = true, _saving = false;
  String? _success;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _nameCtrl.dispose(); _companyCtrl.dispose(); _phoneCtrl.dispose();
    _cityCtrl.dispose(); _stateCtrl.dispose(); _pincodeCtrl.dispose(); _streetCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _profile = await AuthService.getCurrentProfile();
    if (_profile != null && mounted) {
      _nameCtrl.text    = _profile!.fullName ?? '';
      _companyCtrl.text = _profile!.companyName ?? '';
      _phoneCtrl.text   = _profile!.phone ?? '';
      _cityCtrl.text    = _profile!.city ?? '';
      _stateCtrl.text   = _profile!.state ?? '';
      _pincodeCtrl.text = _profile!.pincode ?? '';
      _streetCtrl.text  = _profile!.street ?? '';
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _success = null; });
    await Supabase.instance.client.from('profiles').update({
      'full_name': _nameCtrl.text.trim(),
      'company_name': _companyCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'pincode': _pincodeCtrl.text.trim(),
      'street': _streetCtrl.text.trim(),
    }).eq('id', _profile!.id);
    if (mounted) setState(() { _saving = false; _success = 'Profile updated successfully!'; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy, elevation: 0,
        title: Text('Company Profile', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () async {
              await AuthService.signOut();
              if (mounted) context.go('/role');
            },
            child: Text('Logout', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryAmber)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAmber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Avatar header
                Center(child: Column(children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: AppColors.primaryNavy, borderRadius: BorderRadius.circular(20)),
                    child: Center(child: Text(_profile?.initials ?? '--',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))),
                  ),
                  const SizedBox(height: 10),
                  Text(_profile?.displayName ?? '—', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(100)),
                    child: Text('MANUFACTURER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryNavy, letterSpacing: 0.8)),
                  ),
                ])),
                const SizedBox(height: 28),

                _sLabel('Basic Information'),
                Fleet1TextField(label: 'Full Name *', hint: 'Your full name', controller: _nameCtrl, prefixIcon: Icons.person_outline_rounded),
                const SizedBox(height: 14),
                Fleet1TextField(label: 'Company Name *', hint: 'Company name', controller: _companyCtrl, prefixIcon: Icons.business_outlined),
                const SizedBox(height: 14),
                Fleet1TextField(label: 'Phone *', hint: '9876543210', controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, prefixIcon: Icons.phone_outlined),

                const SizedBox(height: 24),
                _sLabel('Address'),
                Fleet1TextField(label: 'Street / Area', hint: 'Plot 23, Sector 5', controller: _streetCtrl, prefixIcon: Icons.home_outlined),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Fleet1TextField(label: 'City *', hint: 'Delhi', controller: _cityCtrl, prefixIcon: Icons.location_city_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: Fleet1TextField(label: 'State *', hint: 'Delhi', controller: _stateCtrl, prefixIcon: Icons.map_outlined)),
                ]),
                const SizedBox(height: 14),
                Fleet1TextField(label: 'PIN Code', hint: '110001', controller: _pincodeCtrl, keyboardType: TextInputType.number, prefixIcon: Icons.pin_drop_outlined),

                if (_success != null) ...[
                  const SizedBox(height: 16),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.greenBorder)),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.supportGreen, size: 16),
                      const SizedBox(width: 8),
                      Text(_success!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.supportGreen)),
                    ])),
                ],

                const SizedBox(height: 28),
                PrimaryButton(label: 'Save Changes', onTap: _save, loading: _saving, icon: Icons.save_rounded),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Sign Out',
                  onTap: () async { await AuthService.signOut(); if (mounted) context.go('/role'); },
                  outline: true,
                  icon: Icons.logout_rounded,
                ),
                const SizedBox(height: 32),
              ]),
            ),
    );
  }

  Widget _sLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8)),
  );
}
