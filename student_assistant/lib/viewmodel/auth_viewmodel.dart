// GROUP MEMBERS: [Add your names and student numbers here]

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:student_assistant/models/student_model.dart';
import 'package:student_assistant/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  StudentModel? _currentStudent;
  String? _userRole;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  StudentModel? get currentStudent => _currentStudent;
  String? get userRole => _userRole;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _userRole == 'admin';
  bool get isStudent => _userRole == 'student';
  String? get currentUserId => _currentUser?.id;
  String? get currentUserEmail => _currentUser?.email;
  String get currentStudentName => _currentStudent?.fullName ?? 'Student';
  String get currentStudentNumber => _currentStudent?.studentNumber ?? '';
  int get currentYearOfStudy => _currentStudent?.yearOfStudy ?? 1;
  String get currentDepartment => _currentStudent?.department ?? '';

  Future<void> init() async {
    _currentUser = _supabase.auth.currentUser;
    if (_currentUser != null) {
      await _loadUserProfile();
      await _loadUserRole();
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', _currentUser!.id)
          .single();
      _currentStudent = StudentModel.fromJson(response);
    } catch (e) {
      // Profile not found yet
    }
  }

  Future<void> _loadUserRole() async {
    if (_currentUser == null) return;
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', _currentUser!.id)
          .single();
      _userRole = response['role'] as String? ?? 'student';
    } catch (e) {
      _userRole = 'student';
    }
  }

  Future<bool> signIn(String email, String password, {String? adminSecretCode}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        _errorMessage = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = response.user;
      
      // Check if this is an admin login attempt with secret code
      if (adminSecretCode != null && adminSecretCode == SupabaseConfig.adminSecretCode) {
        // Valid secret code provided - this is an admin
        _userRole = 'admin';
        
        await _supabase.from('profiles').upsert({
          'id': _currentUser!.id,
          'email': email.trim(),
          'full_name': email.trim().split('@').first,
          'role': 'admin',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        await _loadUserProfile();
      } else {
        // Normal student login
        await _loadUserProfile();
        await _loadUserRole();
        
        // If user exists and is admin but didn't provide secret code, don't allow admin access
        if (_userRole == 'admin') {
          _userRole = 'student';
          await _supabase.from('profiles').update({'role': 'student'}).eq('id', _currentUser!.id);
        }
        
        // If no profile exists, create a student profile
        if (_currentStudent == null) {
          await _supabase.from('profiles').insert({
            'id': _currentUser!.id,
            'email': email.trim(),
            'full_name': email.trim().split('@').first,
            'student_number': 'STU${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}',
            'year_of_study': 1,
            'department': 'Not Specified',
            'role': 'student',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          await _loadUserProfile();
          _userRole = 'student';
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // =============================================
  // UPDATE STUDENT PROFILE
  // =============================================
  Future<bool> updateProfile({
    required String fullName,
    String? phoneNumber,
    int? yearOfStudy,
    String? department,
    File? profileImage,
  }) async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? profilePictureUrl = _currentStudent?.profilePictureUrl;
      
      // Upload new profile picture if provided
      if (profileImage != null) {
        final storageService = StorageService();
        profilePictureUrl = await storageService.uploadProfilePicture(
          _currentUser!.id, 
          profileImage,
        );
      }
      
      // Update profile in database
      final updates = {
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (phoneNumber != null && phoneNumber.isNotEmpty) updates['phone_number'] = phoneNumber;
      if (yearOfStudy != null) updates['year_of_study'] = yearOfStudy.toString();
      if (department != null && department.isNotEmpty) updates['department'] = department;
      if (profilePictureUrl != null) updates['profile_picture_url'] = profilePictureUrl;
      
      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', _currentUser!.id);
      
      // Update local student object
      _currentStudent = _currentStudent?.copyWith(
        fullName: fullName,
        phoneNumber: phoneNumber ?? _currentStudent?.phoneNumber,
        yearOfStudy: yearOfStudy ?? _currentStudent?.yearOfStudy,
        department: department ?? _currentStudent?.department,
        profilePictureUrl: profilePictureUrl ?? _currentStudent?.profilePictureUrl,
        updatedAt: DateTime.now(),
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get current student profile
  StudentModel? getCurrentStudent() {
    return _currentStudent;
  }

  // =============================================
  // SIGN UP (For admin use only - optional)
  // =============================================
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String studentNumber,
    required int yearOfStudy,
    required String department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        _errorMessage = 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'email': email.trim(),
        'full_name': fullName,
        'student_number': studentNumber,
        'year_of_study': yearOfStudy,
        'department': department,
        'role': 'student',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      _currentUser = response.user;
      _userRole = 'student';
      await _loadUserProfile();
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // =============================================
  // SIGN OUT
  // =============================================
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _supabase.auth.signOut();
    _currentUser = null;
    _currentStudent = null;
    _userRole = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // =============================================
  // CLEAR ERROR
  // =============================================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}