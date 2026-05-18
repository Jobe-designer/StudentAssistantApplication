enum ApplicationStatus {
  pending,
  approved,
  rejected,
}

class Application {
  final String id;
  final String studentId;
  final String yearOfStudy;
  final ApplicationStatus status;
  final DateTime createdAt;
  final List<ApplicationModule> modules;
  final String? documentUrl;
  final bool eligibilityConfirmed;
  final String? applicantName;
  final String? applicantStudentNumber;
  final String? idDocumentUrl;
  final String? matricDocumentUrl;
  final String?   academicRecordUrl;
  final String? cvUrl;

  const Application({
    required this.id,
    required this.studentId,
    required this.yearOfStudy,
    required this.status,
    required this.createdAt,
    required this.modules,
    required this.eligibilityConfirmed,
    this.documentUrl,
    this.applicantName,
    this.applicantStudentNumber,
    this.idDocumentUrl,
    this.matricDocumentUrl,
    this.academicRecordUrl,
    this.cvUrl, required cvDocumentUrl, DateTime? updatedAt,
  });

  bool get isPending => status == ApplicationStatus.pending;

  // In your application.dart model

factory Application.fromJson(Map<String, dynamic> json) {
  // Parse modules from the nested relationship
  List<ApplicationModule> modules = [];
  
  if (json['modules'] != null && json['modules'] is List) {
    modules = (json['modules'] as List).map((moduleJson) {
      return ApplicationModule(
        academicLevel: moduleJson['academic_level'] ?? '',
        moduleName: moduleJson['module_name'] ?? '',
      );
    }).toList();
  }
  
  // Also handle if modules are in a different format
  if (modules.isEmpty && json['modules'] != null && json['modules'] is Map) {
    // Handle if modules is an object
  }

  return Application(
    id: json['id'].toString(),
    studentId: json['student_id'].toString(),
    yearOfStudy: json['year_of_study'] ?? '',
    status: _parseStatus(json['status']),
    eligibilityConfirmed: json['eligibility_confirmed'] ?? false,
    idDocumentUrl: json['id_document_url'],
    matricDocumentUrl: json['matric_document_url'],
    academicRecordUrl: json['academic_record_url'],
    cvDocumentUrl: json['cv_document_url'],
    modules: modules,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    // Get profile info from nested profiles if available
    applicantName: json['profiles'] != null ? json['profiles']['full_name'] : null,
    applicantStudentNumber: json['profiles'] != null ? json['profiles']['user_number'] : null,
  );
}

  static ApplicationStatus _parseStatus(
    dynamic value,
  ) {
    if (value == null) {
      return ApplicationStatus.pending;
    }

    final status =
        value.toString().toLowerCase();

    switch (status) {
      case 'approved':
        return ApplicationStatus.approved;

      case 'rejected':
        return ApplicationStatus.rejected;

      default:
        return ApplicationStatus.pending;
    }
  }

  copyWith({required String status, required String rejectionReason, required DateTime updatedAt}) {}
}

class ApplicationModule {
  final String academicLevel;
  final String moduleName;

  const ApplicationModule({
    required this.academicLevel,
    required this.moduleName,
  });

  factory ApplicationModule.fromJson(
    Map<String, dynamic> json,
  ) {
    return ApplicationModule(
      academicLevel:
          json['academic_level']
                  ?.toString() ??
              '',

      moduleName:
          json['module_name']
                  ?.toString() ??
              '',
    );
  }

  Map<String, dynamic> toInsertJson(
    String applicationId,
  ) {
    return {
      'application_id': applicationId,
      'academic_level': academicLevel,
      'module_name': moduleName,
    };
  }
}

class PickedDocument {
  final String fileName;
  final List<int> bytes;

  const PickedDocument({
    required this.fileName,
    required this.bytes,
  });
}