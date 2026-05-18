// lib/viewmodels/application_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:student_assistant/models/application_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ApplicationViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<ApplicationModel> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialLoad = true;

  // Getters
  List<ApplicationModel> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  int get pendingCount => _applications.where((a) => a.status == 'pending').length;
  int get approvedCount => _applications.where((a) => a.status == 'approved').length;
  int get rejectedCount => _applications.where((a) => a.status == 'rejected').length;
  
  ApplicationModel? get pendingApplication {
    try {
      return _applications.firstWhere((a) => a.status == 'pending');
    } catch (e) {
      return null;
    }
  }
  
  bool get hasPendingApplication => pendingApplication != null;
  bool get canSubmitApplication => !hasPendingApplication && approvedCount == 0;

  void reset() {
    _applications = [];
    _isLoading = false;
    _errorMessage = null;
    _isInitialLoad = true;
    notifyListeners();
  }

  Future<void> fetchMyApplications(String userId) async {
    if (_isLoading && !_isInitialLoad) return;
    
    _isLoading = true;
    _isInitialLoad = false;
    notifyListeners();

    try {
      final response = await _supabase
          .from('applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _applications = response.map((json) => ApplicationModel.fromJson(json)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllApplications() async {
    if (_isLoading && !_isInitialLoad) return;
    
    _isLoading = true;
    _isInitialLoad = false;
    notifyListeners();

    try {
      final response = await _supabase
          .from('applications')
          .select()
          .order('created_at', ascending: false);

      _applications = response.map((json) => ApplicationModel.fromJson(json)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitApplication(ApplicationModel application) async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonData = application.toJson();
      jsonData['created_at'] = DateTime.now().toIso8601String();
      jsonData['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from('applications')
          .insert(jsonData)
          .select();

      if (response.isNotEmpty) {
        _applications.insert(0, ApplicationModel.fromJson(response.first));
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateApplication(ApplicationModel application) async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonData = application.toJson();
      jsonData['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('applications')
          .update(jsonData)
          .eq('id', application.id);

      final index = _applications.indexWhere((a) => a.id == application.id);
      if (index != -1) {
        _applications[index] = application;
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

  Future<bool> approveApplication(String applicationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updates = {
        'status': 'approved',
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('applications')
          .update(updates)
          .eq('id', applicationId)
          .select();

      if (response.isNotEmpty) {
        final index = _applications.indexWhere((a) => a.id == applicationId);
        if (index != -1) {
          _applications[index] = _applications[index].copyWith(
            status: 'approved',
            updatedAt: DateTime.now(),
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectApplication(String applicationId, String rejectionReason) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updates = {
        'status': 'rejected',
        'rejection_reason': rejectionReason,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('applications')
          .update(updates)
          .eq('id', applicationId)
          .select();

      if (response.isNotEmpty) {
        final index = _applications.indexWhere((a) => a.id == applicationId);
        if (index != -1) {
          _applications[index] = _applications[index].copyWith(
            status: 'rejected',
            rejectionReason: rejectionReason,
            updatedAt: DateTime.now(),
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteApplication(String applicationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase
          .from('applications')
          .delete()
          .eq('id', applicationId);

      _applications.removeWhere((a) => a.id == applicationId);
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

  Future<bool> updateApplicationStatus(String applicationId, String status, {String? rejectionReason}) async {
    if (status == 'approved') {
      return approveApplication(applicationId);
    } else if (status == 'rejected') {
      return rejectApplication(applicationId, rejectionReason ?? 'No reason provided');
    }
    return false;
  }
}