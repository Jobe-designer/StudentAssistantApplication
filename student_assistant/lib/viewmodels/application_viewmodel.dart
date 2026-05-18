import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application.dart';

class ApplicationViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Application> _applications = [];

  bool _isLoading = false;

  List<Application> get applications => _applications;

  bool get isLoading => _isLoading;

  String get _applicationSelect =>
      '''
      *,
      modules:application_modules(*),
      profiles:student_id(
        full_name,
        user_number
      )
      ''';

  // FETCH USER APPLICATIONS
  Future<void> fetchUserApplications() async {
    _setLoading(true);

    try {
      final userId = _supabase.auth.currentUser!.id;

      final data = await _supabase
          .from('applications')
          .select(_applicationSelect)
          .eq('student_id', userId)
          .order(
            'created_at',
            ascending: false,
          );

      _applications = (data as List)
          .map(
            (item) => Application.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('Error fetching applications: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // FETCH ALL APPLICATIONS
  Future<void> fetchAllApplications({
    ApplicationStatus? filterStatus,
  }) async {
    _setLoading(true);

    try {
      var query = _supabase
          .from('applications')
          .select(_applicationSelect);

      if (filterStatus != null) {
        query = query.eq('status', filterStatus.name);
      }

      final data = await query.order('created_at', ascending: false);

      _applications = (data as List)
          .map(
            (item) => Application.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      debugPrint('Error fetching all applications: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // SUBMIT APPLICATION
  Future<void> submitApplication({
    required String yearOfStudy,
    required List<ApplicationModule> modules,
    required bool eligibilityConfirmed,
    required PickedDocument idDocument,
    required PickedDocument matricDocument,
    required PickedDocument academicRecord,
    required PickedDocument cvDocument,
  }) async {
    _validateApplication(modules, eligibilityConfirmed);

    _setLoading(true);

    try {
      final userId = _supabase.auth.currentUser!.id;

      final existing = await _supabase
          .from('applications')
          .select('id')
          .eq('student_id', userId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('You have already submitted an application.');
      }

      // UPLOAD DOCUMENTS
      final idUrl = await _uploadDocument(userId, idDocument, 'id_copy');
      final matricUrl = await _uploadDocument(userId, matricDocument, 'matric_results');
      final academicUrl = await _uploadDocument(userId, academicRecord, 'academic_record');

      // INSERT APPLICATION
      final appData = await _supabase.from('applications').insert({
        'student_id': userId,
        'year_of_study': yearOfStudy,
        'status': ApplicationStatus.pending.name,
        'eligibility_confirmed': eligibilityConfirmed,
        'id_document_url': idUrl,
        'matric_document_url': matricUrl,
        'academic_record_url': academicUrl,
      }).select('id').single();

      final applicationId = appData['id'] as String;

      // INSERT MODULES
      await _supabase.from('application_modules').insert(
        modules.map((module) => module.toInsertJson(applicationId)).toList(),
      );

      await fetchUserApplications();
    } finally {
      _setLoading(false);
    }
  }

  // =============================================
  // SUBMIT APPLICATION WITH DOCUMENTS (Wrapper)
  // =============================================
  Future<void> submitApplicationWithDocuments({
    required String yearOfStudy,
    required List<ApplicationModule> modules,
    required bool eligibilityConfirmed,
    required PickedDocument idDocument,
    required PickedDocument matricDocument,
    required PickedDocument academicRecord,
    required PickedDocument cvDocument,
  }) async {
    await submitApplication(
      yearOfStudy: yearOfStudy,
      modules: modules,
      eligibilityConfirmed: eligibilityConfirmed,
      idDocument: idDocument,
      matricDocument: matricDocument,
      academicRecord: academicRecord,
      cvDocument: cvDocument,
    );
  }

  // UPDATE APPLICATION
  Future<void> updateApplication({
    required Application application,
    required String yearOfStudy,
    required List<ApplicationModule> modules,
    required bool eligibilityConfirmed,
    PickedDocument? idDocument,
    PickedDocument? matricDocument,
    PickedDocument? academicRecord,
    PickedDocument? cvDocument,
  }) async {
    if (!application.isPending) {
      throw Exception('Only pending applications can be edited.');
    }

    _validateApplication(modules, eligibilityConfirmed);

    _setLoading(true);

    try {
      final userId = _supabase.auth.currentUser!.id;

      final updateData = <String, dynamic>{
        'year_of_study': yearOfStudy,
        'eligibility_confirmed': eligibilityConfirmed,
      };

      // OPTIONAL DOCUMENT REPLACEMENTS
      if (idDocument != null) {
        updateData['id_document_url'] = await _uploadDocument(userId, idDocument, 'id_copy');
      }

      if (matricDocument != null) {
        updateData['matric_document_url'] = await _uploadDocument(userId, matricDocument, 'matric_results');
      }

      if (academicRecord != null) {
        updateData['academic_record_url'] = await _uploadDocument(userId, academicRecord, 'academic_record');
      }

      // UPDATE APPLICATION
      await _supabase
          .from('applications')
          .update(updateData)
          .eq('id', application.id)
          .eq('student_id', userId)
          .eq('status', ApplicationStatus.pending.name);

      // REPLACE MODULES
      await _supabase.from('application_modules').delete().eq('application_id', application.id);

      await _supabase.from('application_modules').insert(
        modules.map((module) => module.toInsertJson(application.id)).toList(),
      );

      await fetchUserApplications();
    } finally {
      _setLoading(false);
    }
  }

  // UPDATE STATUS
  Future<void> updateApplicationStatus(
    String id,
    ApplicationStatus status, {
    ApplicationStatus? currentFilter,
  }) async {
    _setLoading(true);

    try {
      await _supabase.from('applications').update({
        'status': status.name,
      }).eq('id', id);

      await fetchAllApplications(filterStatus: currentFilter);
    } catch (error) {
      debugPrint('Error updating status: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // DELETE APPLICATION
  Future<void> deleteApplication(
    String id, {
    bool adminMode = false,
    ApplicationStatus? currentFilter,
    bool pendingOnly = false,
  }) async {
    _setLoading(true);

    try {
      var query = _supabase.from('applications').delete().eq('id', id);

      if (pendingOnly) {
        query = query.eq('status', ApplicationStatus.pending.name);
      }

      await query;

      if (adminMode) {
        await fetchAllApplications(filterStatus: currentFilter);
      } else {
        await fetchUserApplications();
      }
    } catch (error) {
      debugPrint('Error deleting application: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // VALIDATION
  void _validateApplication(
    List<ApplicationModule> modules,
    bool eligibilityConfirmed,
  ) {
    if (modules.isEmpty || modules.length > 2) {
      throw Exception('You must apply for one or two modules only.');
    }

    if (modules.any((module) => module.moduleName.trim().isEmpty)) {
      throw Exception('Every selected module must have a module name.');
    }

    if (!eligibilityConfirmed) {
      throw Exception('You must confirm that you meet the minimum requirements.');
    }
  }

  // DOCUMENT UPLOAD
  Future<String> _uploadDocument(
    String userId,
    PickedDocument document,
    String folder,
  ) async {
    if (!document.fileName.toLowerCase().endsWith('.pdf')) {
      throw Exception('Only PDF documents are allowed.');
    }

    final safeName = document.fileName.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

    final fileName = '$userId/$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _supabase.storage.from('documents').uploadBinary(
      fileName,
      Uint8List.fromList(document.bytes),
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: true,
      ),
    );

    return fileName;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}