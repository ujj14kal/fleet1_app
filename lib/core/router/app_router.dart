import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/role_selection_screen.dart';
import '../../features/auth/manufacturer/m_login_screen.dart';
import '../../features/auth/manufacturer/m_signup_screen.dart';
import '../../features/auth/transporter/t_login_screen.dart';
import '../../features/auth/transporter/t_signup_screen.dart';
// MShell + TShell + all tab screens exported from m_shell.dart
import '../../features/manufacturer/m_shell.dart';
// Transporter tab screens re-exported from t_shell.dart
import '../../features/transporter/t_shell.dart';
import '../../features/driver/d_placeholder_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/role',   builder: (_, __) => const RoleSelectionScreen()),

    // ── Manufacturer auth ─────────────────────────────────
    GoRoute(path: '/manufacturer/login',  builder: (_, __) => const MLoginScreen()),
    GoRoute(path: '/manufacturer/signup', builder: (_, __) => const MSignupScreen()),

    // ── Transporter auth ──────────────────────────────────
    GoRoute(path: '/transporter/login',  builder: (_, __) => const TLoginScreen()),
    GoRoute(path: '/transporter/signup', builder: (_, __) => const TSignupScreen()),

    // ── Driver (placeholder) ──────────────────────────────
    GoRoute(path: '/driver/login', builder: (_, __) => const DPlaceholderScreen()),

    // ── Manufacturer shell with bottom nav ────────────────
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => MShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/m/home',      builder: (_, __) => const MHomeTab()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/m/shipments', builder: (_, __) => const MShipmentsTab()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/m/create',    builder: (_, __) => const MCreateTab()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/m/tracking',  builder: (_, __) => const MTrackingTab()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/m/profile',   builder: (_, __) => const MProfileTab()),
        ]),
      ],
    ),

    // ── Transporter shell with bottom nav ─────────────────
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => TShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/t/home',      builder: (_, __) => const THomeTab()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/t/assigned',  builder: (_, __) => const TAssignedTab()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/t/handover',  builder: (_, __) => const THandoverTab()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/t/fleet',     builder: (_, __) => const TFleetTab()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/t/profile',   builder: (_, __) => const TProfileTab()),
        ]),
      ],
    ),
  ],
);
