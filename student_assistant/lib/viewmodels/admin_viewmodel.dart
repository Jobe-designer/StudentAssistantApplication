// lib/viewmodels/admin_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:student_assistant/models/application.dart';

class AdminViewModel extends ChangeNotifier {
  List<Application> _allApplications = [];
  List<Application> _filteredApplications = [];
  bool _isLoading = false;
  String? _errorMessage;
  ApplicationStatus?
      _currentFilter; // FIXED: Changed from String to ApplicationStatus
  String _searchQuery = '';

  List<Application> get allApplications => _allApplications;
  List<Application> get filteredApplications => _filteredApplications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ApplicationStatus? get currentFilter =>
      _currentFilter; // FIXED: Changed return type
  String get searchQuery => _searchQuery;

  int get totalApplications => _allApplications.length;
  int get pendingApplications => _allApplications
      .where((app) => app.status == ApplicationStatus.pending)
      .length; // FIXED
  int get approvedApplications => _allApplications
      .where((app) => app.status == ApplicationStatus.approved)
      .length; // FIXED
  int get rejectedApplications => _allApplications
      .where((app) => app.status == ApplicationStatus.rejected)
      .length; // FIXED

  void applyFilters() {
    List<Application> result = [..._allApplications];

    if (_currentFilter != null) {
      result =
          result.where((app) => app.status == _currentFilter).toList(); // FIXED
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((app) {
        return app.studentId.toLowerCase().contains(query) ||
            app.applicantName?.toLowerCase().contains(query) == true ||
            app.applicantStudentNumber?.toLowerCase().contains(query) == true;
      }).toList();
    }

    _filteredApplications = result;
    notifyListeners();
  }

  void setFilter(ApplicationStatus? filter) {
    // FIXED: Parameter type changed
    _currentFilter = filter;
    applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    applyFilters();
  }

  void clearFilters() {
    _currentFilter = null; // FIXED: Changed from 'all' to null
    _searchQuery = '';
    applyFilters();
  }

  String? validateRejectionReason(String? reason) {
    if (reason == null || reason.trim().isEmpty) {
      return 'Rejection reason is required';
    }
    if (reason.trim().length < 10) {
      return 'Please provide at least 10 characters';
    }
    return null;
  }

  Future<List<Application>> loadAllApplications() async {
    _isLoading = true;
    notifyListeners();

    _allApplications = [];
    _filteredApplications = [];

    _isLoading = false;
    notifyListeners();
    return _allApplications;
  }

  Future<bool> approveApplication(
      String applicationId, String adminNotes) async {
    _isLoading = true;
    notifyListeners();

    final index = _allApplications.indexWhere((app) => app.id == applicationId);
    if (index != -1) {
      final updatedApp = _allApplications[index].copyWith(
          status: ApplicationStatus.approved.name,
          updatedAt: DateTime.now(),
          rejectionReason: '');
      _allApplications[index] = updatedApp;
      applyFilters();
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> rejectApplication(
      String applicationId, String rejectionReason) async {
    _isLoading = true;
    notifyListeners();

    final index = _allApplications.indexWhere((app) => app.id == applicationId);
    if (index != -1) {
      final updatedApp = _allApplications[index].copyWith(
        status: ApplicationStatus
            .rejected.name, // FIXED: Using enum instead of string
        rejectionReason: rejectionReason,
        updatedAt: DateTime.now(),
      );
      _allApplications[index] = updatedApp;
      applyFilters();
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteApplication(String applicationId) async {
    _isLoading = true;
    notifyListeners();

    _allApplications.removeWhere((app) => app.id == applicationId);
    applyFilters();

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
