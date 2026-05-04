import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/fleet1_app_bar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class TLoginScreen extends StatefulWidget {
  const TLoginScreen({super.key});
  @override
  State<TLoginScreen> createState() => _TLoginScreenState();
}

class _TLoginScreenState extends State<TLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false, _obscure = true;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final res = await AuthService.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.isSuccess) {
      if (res.profile?.role == 'transporter') {
        context.go('/t/home');
      } else {
        setState(() => _error = 'This account is not a transporter account.');
      }
    } else {
      setState(() => _error = res.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: Fleet1AppBar(title: 'Transporter Login', onBack: () => context.go('/role')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Amber accent header for transporter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.amberLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.amberBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_shipping_rounded, color: AppColors.primaryAmber, size: 14),
                const SizedBox(width: 6),
                Text('TRANSPORTER PORTAL', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: AppColors.primaryAmber, letterSpacing: 1,
                )),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Welcome back 👋', style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
            )),
            const SizedBox(height: 6),
            Text('Sign in to your transporter dashboard', style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textSecondary,
            )),
            const SizedBox(height: 32),

            Fleet1TextField(label: 'Email Address', hint: 'your@company.com', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
            const SizedBox(height: 16),
            Fleet1TextField(
              label: 'Password', hint: '••••••••', controller: _passCtrl, obscureText: _obscure,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              onSuffixTap: () => setState(() => _obscure = !_obscure),
            ),

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
            PrimaryButton(label: 'Sign In to Dashboard', onTap: _login, loading: _loading, icon: Icons.login_rounded),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("New to Fleet1? ", style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => context.go('/transporter/signup'),
                child: Text('Apply to Join →', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
