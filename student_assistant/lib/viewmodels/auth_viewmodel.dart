// lib/viewmodels/auth_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  UserProfile? _profile;
  bool _isLoading = false;

  // =============================================
  // GETTERS
  // =============================================
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _supabase.auth.currentUser != null;
  bool get isAdmin => _profile?.role == UserRole.admin;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  String? get currentUserEmail => _supabase.auth.currentUser?.email;

  // =============================================
  // CONSTRUCTOR
  // =============================================
  AuthViewModel() {
    _supabase.auth.onAuthStateChange.listen((_) async {
      if (isAuthenticated) {
        await fetchProfile();
      } else {
        _profile = null;
        notifyListeners();
      }
    });
    _init();
  }

  // =============================================
  // INIT
  // =============================================
  Future<void> _init() async {
    if (isAuthenticated) {
      await fetchProfile();
    }
  }

  // =============================================
  // FETCH PROFILE
  // =============================================
  Future<void> fetchProfile() async {
    try {
      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null) {
        _profile = null;
        notifyListeners();
        return;
      }

      final userId = currentUser.id;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        debugPrint('No profile found for user');
        _profile = null;
        notifyListeners();
        return;
      }

      _profile = UserProfile.fromJson(data);
      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching profile: $error');
      _profile = null;
      notifyListeners();
    }
  }

  // =============================================
  // SIGN IN (WITHOUT ADMIN CODE - HANDLED IN UI)
  // =============================================
  Future<void> signIn(String email, String password) async {
    _setLoading(true);

    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await fetchProfile();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // =============================================
  // SIGN UP
  // =============================================
  Future<void> signUp(
    String email,
    String password,
    String fullName,
    String studentNumber,
  ) async {
    _setLoading(true);

    try {
      // Check if student number already exists
      final existingStudent = await _supabase
          .from('profiles')
          .select()
          .eq('user_number', studentNumber.trim())
          .maybeSingle();

      if (existingStudent != null) {
        throw Exception('Student number already registered');
      }

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Registration failed.');
      }

      await _supabase.from('profiles').insert({
        'id': user.id,
        'full_name': fullName.trim(),
        'user_number': studentNumber.trim(),
        'email': email.trim(),
        'role': 'student',
      });

      await fetchProfile();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Registration failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // =============================================
  // SIGN OUT
  // =============================================
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _profile = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // =============================================
  // UPDATE PROFILE
  // =============================================
  Future<void> updateProfile({String? fullName, String? userNumber}) async {
    _setLoading(true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName.trim();
      if (userNumber != null) updates['user_number'] = userNumber.trim();
      
      if (updates.isNotEmpty) {
        await _supabase.from('profiles').update(updates).eq('id', userId);
        await fetchProfile();
      }
    } catch (e) {
      throw Exception('Update failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}