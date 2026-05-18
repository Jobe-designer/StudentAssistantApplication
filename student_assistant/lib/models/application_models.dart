// GROUP MEMBERS: [Add your names and student numbers here]

class ApplicationModel {
  final String id;
  final String userId;
  final String studentNumber;
  final String fullName;
  final String email;
  final int yearOfStudy;
  final String firstModuleLevel;
  final String firstModuleName;
  final String firstModuleReason;
  final bool hasSecondModule;
  final String? secondModuleLevel;
  final String? secondModuleName;
  final String? secondModuleReason;
  
  // Multiple documents
  final String? cvUrl;
  final String? academicTranscriptUrl;
  final String? matricResultsUrl;
  final String? idDocumentUrl;
  
  final bool eligibilityConfirmed;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ApplicationModel({
    required this.id,
    required this.userId,
    required this.studentNumber,
    required this.fullName,
    required this.email,
    required this.yearOfStudy,
    required this.firstModuleLevel,
    required this.firstModuleName,
    required this.firstModuleReason,
    required this.hasSecondModule,
    this.secondModuleLevel,
    this.secondModuleName,
    this.secondModuleReason,
    this.cvUrl,
    this.academicTranscriptUrl,
    this.matricResultsUrl,
    this.idDocumentUrl,
    required this.eligibilityConfirmed,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      studentNumber: json['student_number'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      yearOfStudy: json['year_of_study'] ?? 1,
      firstModuleLevel: json['first_module_level'] ?? '',
      firstModuleName: json['first_module_name'] ?? '',
      firstModuleReason: json['first_module_reason'] ?? '',
      hasSecondModule: json['has_second_module'] ?? false,
      secondModuleLevel: json['second_module_level'],
      secondModuleName: json['second_module_name'],
      secondModuleReason: json['second_module_reason'],
      cvUrl: json['cv_url'],
      academicTranscriptUrl: json['academic_transcript_url'],
      matricResultsUrl: json['matric_results_url'],
      idDocumentUrl: json['id_document_url'],
      eligibilityConfirmed: json['eligibility_confirmed'] ?? false,
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  get academicRecordUrl => null;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'student_number': studentNumber,
      'full_name': fullName,
      'email': email,
      'year_of_study': yearOfStudy,
      'first_module_level': firstModuleLevel,
      'first_module_name': firstModuleName,
      'first_module_reason': firstModuleReason,
      'has_second_module': hasSecondModule,
      if (secondModuleLevel != null) 'second_module_level': secondModuleLevel,
      if (secondModuleName != null) 'second_module_name': secondModuleName,
      if (secondModuleReason != null) 'second_module_reason': secondModuleReason,
      if (cvUrl != null && cvUrl!.isNotEmpty) 'cv_url': cvUrl,
      if (academicTranscriptUrl != null && academicTranscriptUrl!.isNotEmpty) 'academic_transcript_url': academicTranscriptUrl,
      if (matricResultsUrl != null && matricResultsUrl!.isNotEmpty) 'matric_results_url': matricResultsUrl,
      if (idDocumentUrl != null && idDocumentUrl!.isNotEmpty) 'id_document_url': idDocumentUrl,
      'eligibility_confirmed': eligibilityConfirmed,
      'status': status,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    };
  }

  ApplicationModel copyWith({
    String? id,
    String? userId,
    String? studentNumber,
    String? fullName,
    String? email,
    int? yearOfStudy,
    String? firstModuleLevel,
    String? firstModuleName,
    String? firstModuleReason,
    bool? hasSecondModule,
    String? secondModuleLevel,
    String? secondModuleName,
    String? secondModuleReason,
    String? cvUrl,
    String? academicTranscriptUrl,
    String? matricResultsUrl,
    String? idDocumentUrl,
    bool? eligibilityConfirmed,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studentNumber: studentNumber ?? this.studentNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      firstModuleLevel: firstModuleLevel ?? this.firstModuleLevel,
      firstModuleName: firstModuleName ?? this.firstModuleName,
      firstModuleReason: firstModuleReason ?? this.firstModuleReason,
      hasSecondModule: hasSecondModule ?? this.hasSecondModule,
      secondModuleLevel: secondModuleLevel ?? this.secondModuleLevel,
      secondModuleName: secondModuleName ?? this.secondModuleName,
      secondModuleReason: secondModuleReason ?? this.secondModuleReason,
      cvUrl: cvUrl ?? this.cvUrl,
      academicTranscriptUrl: academicTranscriptUrl ?? this.academicTranscriptUrl,
      matricResultsUrl: matricResultsUrl ?? this.matricResultsUrl,
      idDocumentUrl: idDocumentUrl ?? this.idDocumentUrl,
      eligibilityConfirmed: eligibilityConfirmed ?? this.eligibilityConfirmed,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}