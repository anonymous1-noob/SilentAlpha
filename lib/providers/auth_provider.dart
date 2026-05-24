import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => SupabaseService.currentUser != null;

  AuthProvider() {
    _initSession();
    SupabaseService.authStateChanges.listen(_onAuthStateChange);
  }

  Future<void> _initSession() async {
    if (SupabaseService.currentUser != null) {
      await _loadProfile(SupabaseService.currentUser!.id);
    }
  }

  Future<void> _onAuthStateChange(AuthState state) async {
    if (state.session != null) {
      await _loadProfile(state.session!.user.id);
    } else {
      _user = null;
      notifyListeners();
    }
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final data = await SupabaseService.getProfile(userId);
      if (data != null) {
        _user = AppUser.fromMap(data);
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('[AuthProvider] _loadProfile: $e\n$st');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String handle,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await SupabaseService.signUp(
        email: email,
        password: password,
        handle: handle,
      );
      if (res.user != null) await _loadProfile(res.user!.id);
      return res.user != null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await SupabaseService.signIn(email: email, password: password);
      if (res.user != null) await _loadProfile(res.user!.id);
      return res.user != null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? handle,
    String? bio,
    String? tagline,
    String? avatarUrl,
  }) async {
    if (_user == null) return;
    final data = <String, dynamic>{};
    if (handle != null) data['handle'] = handle;
    if (bio != null) data['bio'] = bio;
    if (tagline != null) data['tagline'] = tagline;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    await SupabaseService.updateProfile(_user!.id, data);
    _user = _user!.copyWith(
      handle: handle,
      bio: bio,
      tagline: tagline,
      avatarUrl: avatarUrl,
    );
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
