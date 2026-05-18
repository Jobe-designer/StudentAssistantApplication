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
    this.cvUrl,
  });

  bool get isPending => status == ApplicationStatus.pending;

  factory Application.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];

    return Application(
      id: json['id']?.toString() ?? '',

      studentId:
          json['student_id']?.toString() ?? '',

      yearOfStudy:
          json['year_of_study']?.toString() ?? '',

      status: _parseStatus(
        json['status'],
      ),

      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(
                      json['created_at']
                          .toString(),
                    ) ??
                    DateTime.now()
              : DateTime.now(),

      modules:
          (json['modules'] as List? ?? [])
              .map(
                (module) =>
                    ApplicationModule.fromJson(
                  module
                      as Map<String, dynamic>,
                ),
              )
              .toList(),

      documentUrl:
          json['document_url']?.toString(),

      eligibilityConfirmed:
          json['eligibility_confirmed'] == true,

      applicantName:
          profile is Map
              ? profile['full_name']
                  ?.toString()
              : null,

      applicantStudentNumber:
          profile is Map
              ? profile['student_number']
                  ?.toString()
              : null,
              idDocumentUrl:
          json[
                  'id_document_url']
              as String?,

      matricDocumentUrl:
          json[
                  'matric_document_url']
              as String?,

      academicRecordUrl:
          json[
                  'academic_record_url']
              as String?,
              cvUrl:
    json['cv_url']
        as String?,
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