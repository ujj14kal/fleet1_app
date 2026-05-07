import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class PlatformScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final VoidCallback? onBack;

  const PlatformScaffold({super.key, required this.body, required this.title, this.actions, this.floatingActionButton, this.onBack});

  bool get _isCupertino => defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    if (_isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppColors.primaryNavy,
          middle: Text(title, style: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.w700)),
          leading: onBack != null ? GestureDetector(
            onTap: onBack,
            child: const Icon(CupertinoIcons.back, color: AppColors.white),
          ) : null,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: actions ?? []),
        ),
        child: SafeArea(child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: onBack != null ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack) : null,
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: actions,
        backgroundColor: AppColors.primaryNavy,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isCupertino = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    if (isCupertino) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryAmber,
        foregroundColor: AppColors.supportDark,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
    );
  }
}
