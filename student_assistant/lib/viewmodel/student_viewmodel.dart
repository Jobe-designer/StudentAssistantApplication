// GROUP MEMBERS: [Add your names and student numbers here]

import 'package:flutter/foundation.dart';
import 'package:student_assistant/models/application_models.dart';

import '../models/student_model.dart';


class StudentViewModel extends ChangeNotifier {
 
  
  StudentModel? _currentStudent;
  List<ApplicationModel> _myApplications = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  StudentModel? get currentStudent => _currentStudent;
  List<ApplicationModel> get myApplications => _myApplications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  String get currentStudentId => _currentStudent?.id ?? '';
  String get currentStudentNumber => _currentStudent?.studentNumber ?? '';
  String get currentStudentName => _currentStudent?.fullName ?? '';
  String get currentStudentEmail => _currentStudent?.email ?? '';
  int get currentYearOfStudy => _currentStudent?.yearOfStudy ?? 1;
  bool get isStudentLoggedIn => _currentStudent != null;
  
  ApplicationModel? get pendingApplication {
    try {
      return _myApplications.firstWhere((app) => app.status == 'pending');
    } catch (e) {
      return null;
    }
  }
  
  ApplicationModel? get approvedApplication {
    try {
      return _myApplications.firstWhere((app) => app.status == 'approved');
    } catch (e) {
      return null;
    }
  }
  
  bool get hasActiveApplication => pendingApplication != null;
  bool get canSubmitApplication => !hasActiveApplication && approvedApplication == null;

  String? getApplicationSubmissionError() {
    if (hasActiveApplication) {
      return 'You already have a pending application';
    }
    if (approvedApplication != null) {
      return 'You have already been approved';
    }
    return null;
  }

  bool canEditApplication(ApplicationModel application) {
    return application.status == 'pending' && application.userId == _currentStudent?.id;
  }

  bool canDeleteApplication(ApplicationModel application) {
    return application.status == 'pending' && application.userId == _currentStudent?.id;
  }

  Future<void> loadStudentProfile(String studentId) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    
    _currentStudent = StudentModel(
      id: studentId,
      studentNumber: '202400001',
      fullName: 'John Doe',
      email: 'student@cut.ac.za',
      phoneNumber: '0712345678',
      yearOfStudy: 2,
      department: 'Information Technology',
      profilePictureUrl: null,
      role: 'student',
      createdAt: now,
      updatedAt: now,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyApplications() async {
    _isLoading = true;
    notifyListeners();
    
    _myApplications = [];
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitApplication(ApplicationModel application) async {
    _isLoading = true;
    notifyListeners();

    final submissionError = getApplicationSubmissionError();
    if (submissionError != null) {
      _errorMessage = submissionError;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _myApplications.insert(0, application);
    
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> updateApplication(ApplicationModel application) async {
    _isLoading = true;
    notifyListeners();

    final index = _myApplications.indexWhere((app) => app.id == application.id);
    if (index != -1) {
      _myApplications[index] = application;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteApplication(String applicationId) async {
    _isLoading = true;
    notifyListeners();

    _myApplications.removeWhere((app) => app.id == applicationId);

    _isLoading = false;
    notifyListeners();
    return true;
  }
}