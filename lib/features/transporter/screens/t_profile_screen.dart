import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/models/transporter_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/truck_loader.dart';

class TProfileTab extends StatefulWidget {
  const TProfileTab({super.key});
  @override
  State<TProfileTab> createState() => _TProfileTabState();
}

class _TProfileTabState extends State<TProfileTab> {
  ProfileModel? _profile;
  TransporterModel? _transporter;
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = true, _saving = false;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _profile = await AuthService.getCurrentProfile();
    if (_profile == null) return;
    final trpData = await Supabase.instance.client
        .from('transporters')
        .select()
        .eq('user_id', _profile!.id)
        .maybeSingle();
    if (trpData != null) _transporter = TransporterModel.fromJson(trpData);
    if (mounted) {
      _nameCtrl.text = _profile!.fullName ?? '';
      _companyCtrl.text = _profile!.companyName ?? '';
      _phoneCtrl.text = _profile!.phone ?? '';
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _success = null;
    });
    await Supabase.instance.client
        .from('profiles')
        .update({
          'full_name': _nameCtrl.text.trim(),
          'company_name': _companyCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        })
        .eq('id', _profile!.id);
    if (mounted)
      setState(() {
        _saving = false;
        _success = 'Profile updated!';
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
          'My Profile',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AuthService.signOut();
              if (mounted) context.go('/role');
            },
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryAmber,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: TruckLoader(message: 'Loading profile...'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primaryAmber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              _profile?.initials ?? '--',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.supportDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _profile?.displayName ?? '—',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amberLight,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'TRANSPORTER',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryAmber,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Transporter info
                  if (_transporter != null) ...[
                    _sLabel('Transport Details'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.local_shipping_rounded,
                            label: 'Load Type',
                            value: _transporter!.loadTypeLabel,
                          ),
                          _InfoRow(
                            icon: Icons.location_on_rounded,
                            label: 'Base City',
                            value: _transporter!.operatingFrom ?? '—',
                          ),
                          _InfoRow(
                            icon: Icons.map_outlined,
                            label: 'Cities',
                            value:
                                '${_transporter!.operatingCities.length} cities',
                          ),
                          _InfoRow(
                            icon: Icons.check_circle_rounded,
                            label: 'Status',
                            value: _transporter!.isActive
                                ? 'Active'
                                : 'Inactive',
                            valueColor: _transporter!.isActive
                                ? AppColors.supportGreen
                                : AppColors.secondaryRed,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  _sLabel('Account Information'),
                  Fleet1TextField(
                    label: 'Contact Name',
                    hint: 'Your name',
                    controller: _nameCtrl,
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  Fleet1TextField(
                    label: 'Company Name',
                    hint: 'Company name',
                    controller: _companyCtrl,
                    prefixIcon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 14),
                  Fleet1TextField(
                    label: 'Phone',
                    hint: '9876543210',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    prefixIcon: Icons.phone_outlined,
                  ),

                  if (_success != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greenBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.supportGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _success!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.supportGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Save Changes',
                    onTap: _save,
                    loading: _saving,
                    icon: Icons.save_rounded,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Sign Out',
                    onTap: () async {
                      await AuthService.signOut();
                      if (mounted) context.go('/role');
                    },
                    outline: true,
                    icon: Icons.logout_rounded,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
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
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
