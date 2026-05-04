import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'session_service.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  // ── Sign In ───────────────────────────────────────────────
  static Future<AuthResult> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email, password: password,
      );
      if (res.user == null) return AuthResult.failure('Login failed. Please try again.');
      final profile = await _getProfile(res.user!.id);
      if (profile == null) return AuthResult.failure('Profile not found. Contact support.');
      await SessionService.saveRole(profile.role);
      return AuthResult.success(res.user!, profile);
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  // ── Sign Up — Manufacturer ────────────────────────────────
  static Future<AuthResult> signUpManufacturer({
    required String email,
    required String password,
    required String fullName,
    required String companyName,
    required String phone,
  }) async {
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      if (res.user == null) return AuthResult.failure('Signup failed. Please try again.');

      await _client.from('profiles').upsert({
        'id': res.user!.id,
        'full_name': fullName,
        'company_name': companyName,
        'phone': phone,
        'role': 'manufacturer',
        'is_active': true,
      }, onConflict: 'id');

      final profile = await _getProfile(res.user!.id);
      if (profile == null) return AuthResult.failure('Profile setup failed.');
      await SessionService.saveRole(profile.role);
      return AuthResult.success(res.user!, profile);
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred.');
    }
  }

  // ── Sign Up — Transporter ─────────────────────────────────
  static Future<AuthResult> signUpTransporter({
    required String email,
    required String password,
    required String fullName,
    required String companyName,
    required String phone,
    required String operatingFrom,
    required List<String> operatingCities,
    required String loadType,
    required List<Map<String, dynamic>> trucks,
  }) async {
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      if (res.user == null) return AuthResult.failure('Signup failed. Please try again.');

      // Create profile
      await _client.from('profiles').upsert({
        'id': res.user!.id,
        'full_name': fullName,
        'company_name': companyName,
        'phone': phone,
        'role': 'transporter',
        'is_active': true,
      }, onConflict: 'id');

      // Create transporter record
      final trpRes = await _client.from('transporters').insert({
        'user_id': res.user!.id,
        'company_name': companyName,
        'contact_person': fullName,
        'phone': phone,
        'operating_from': operatingFrom,
        'operating_cities': operatingCities,
        'load_type': loadType,
        'is_active': true,
      }).select().single();

      // Create trucks
      if (trucks.isNotEmpty) {
        final trpId = trpRes['id'] as String;
        await _client.from('trucks').insert(
          trucks.map((t) => {...t, 'transporter_id': trpId}).toList(),
        );
      }

      final profile = await _getProfile(res.user!.id);
      if (profile == null) return AuthResult.failure('Profile setup failed.');
      await SessionService.saveRole(profile.role);
      return AuthResult.success(res.user!, profile);
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // ── Sign Out ──────────────────────────────────────────────
  static Future<void> signOut() async {
    await _client.auth.signOut();
    await SessionService.clear();
  }

  // ── Get current user's profile ────────────────────────────
  static Future<ProfileModel?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return await _getProfile(user.id);
  }

  static Future<ProfileModel?> _getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  static String _mapAuthError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'An account with this email already exists.';
    }
    if (m.contains('password')) {
      return 'Password must be at least 8 characters with uppercase, number & special character.';
    }
    if (m.contains('network') || m.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    return msg;
  }
}

class AuthResult {
  final bool isSuccess;
  final User? user;
  final ProfileModel? profile;
  final String? error;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.profile,
    this.error,
  });

  factory AuthResult.success(User user, ProfileModel profile) =>
      AuthResult._(isSuccess: true, user: user, profile: profile);

  factory AuthResult.failure(String error) =>
      AuthResult._(isSuccess: false, error: error);
}
