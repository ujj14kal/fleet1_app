import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/fleet1_app_bar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class MSignupScreen extends StatefulWidget {
  const MSignupScreen({super.key});
  @override
  State<MSignupScreen> createState() => _MSignupScreenState();
}

class _MSignupScreenState extends State<MSignupScreen> {
  final _nameCtrl    = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _companyCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final name    = _nameCtrl.text.trim();
    final company = _companyCtrl.text.trim();
    final email   = _emailCtrl.text.trim();
    final phone   = _phoneCtrl.text.trim();
    final pass    = _passCtrl.text;

    if ([name, company, email, phone, pass].any((s) => s.isEmpty)) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (phone.length != 10) {
      setState(() => _error = 'Phone number must be exactly 10 digits.');
      return;
    }
    final passRegex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,}$');
    if (!passRegex.hasMatch(pass)) {
      setState(() => _error = 'Password must be 8+ chars with uppercase, number & special character.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final res = await AuthService.signUpManufacturer(
      email: email, password: pass, fullName: name, companyName: company, phone: phone,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.isSuccess) {
      context.go('/m/home');
    } else {
      setState(() => _error = res.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: Fleet1AppBar(title: 'Create Account', onBack: () => context.go('/manufacturer/login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Register as Manufacturer', style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
            )),
            const SizedBox(height: 6),
            Text('Create your Fleet1 manufacturer account', style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textSecondary,
            )),
            const SizedBox(height: 32),

            Fleet1TextField(label: 'Full Name', hint: 'Rajesh Kumar', controller: _nameCtrl, prefixIcon: Icons.person_outline_rounded),
            const SizedBox(height: 16),
            Fleet1TextField(label: 'Company Name', hint: 'Acme Industries Pvt. Ltd.', controller: _companyCtrl, prefixIcon: Icons.business_outlined),
            const SizedBox(height: 16),
            Fleet1TextField(label: 'Email Address', hint: 'rajesh@acme.com', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
            const SizedBox(height: 16),
            Fleet1TextField(label: 'Phone Number', hint: '9876543210', controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, prefixIcon: Icons.phone_outlined),
            const SizedBox(height: 16),
            Fleet1TextField(
              label: 'Password', hint: '••••••••', controller: _passCtrl, obscureText: _obscure,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              onSuffixTap: () => setState(() => _obscure = !_obscure),
            ),
            const SizedBox(height: 8),
            Text('Min 8 chars · 1 uppercase · 1 number · 1 special character',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),

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
            PrimaryButton(label: 'Create Account', onTap: _signup, loading: _loading, icon: Icons.check_circle_outline_rounded),
            const SizedBox(height: 24),
            Center(
              child: RichText(text: TextSpan(children: [
                TextSpan(text: 'Already have an account? ', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                TextSpan(text: 'Sign In', recognizer: TapGestureRecognizer()..onTap = () => context.go('/manufacturer/login'),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}
