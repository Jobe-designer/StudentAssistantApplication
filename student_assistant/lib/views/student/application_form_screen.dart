// lib/views/student/application_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/app_theme.dart';
import '../../models/application_models.dart';
import '../../utils/validate.dart';
import '../../viewmodel/application_viewmodel.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../services/storage_service.dart';

class ApplicationFormScreen extends StatefulWidget {
  final ApplicationModel? application;
  const ApplicationFormScreen({super.key, this.application});

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstReasonController = TextEditingController();
  final _secondReasonController = TextEditingController();

  String? _firstLevel, _firstName;
  String? _secondLevel, _secondName;
  bool _hasSecondModule = false;
  bool _eligibilityConfirmed = false;

  // Document URLs
  String _cvUrl = '';
  String _academicUrl = '';
  String _matricUrl = '';
  String _idUrl = '';

  bool _isSubmitting = false;

  final List<String> _levels = ['Level 1', 'Level 2', 'Level 3', 'Level 4'];
  final List<String> _modules = [
    'Programming Fundamentals', 'Database Systems', 'Web Development',
    'Software Engineering', 'Network Security', 'Mobile App Development',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.application != null) {
      _firstLevel = widget.application!.firstModuleLevel;
      _firstName = widget.application!.firstModuleName;
      _firstReasonController.text = widget.application!.firstModuleReason;
      _hasSecondModule = widget.application!.hasSecondModule;
      _secondLevel = widget.application!.secondModuleLevel;
      _secondName = widget.application!.secondModuleName;
      if (widget.application!.secondModuleReason != null) {
        _secondReasonController.text = widget.application!.secondModuleReason!;
      }
      _eligibilityConfirmed = widget.application!.eligibilityConfirmed;
      _cvUrl = widget.application!.cvUrl ?? '';
      _academicUrl = widget.application!.academicTranscriptUrl ?? '';
      _matricUrl = widget.application!.matricResultsUrl ?? '';
      _idUrl = widget.application!.idDocumentUrl ?? '';
    }
  }

  @override
  void dispose() {
    _firstReasonController.dispose();
    _secondReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type, String documentType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    
    if (result == null) return;
    
    final pickedFile = result.files.single;
    if (pickedFile.path == null) return;
    
    final file = File(pickedFile.path!);
    final authVM = context.read<AuthViewModel>();
    final storageService = StorageService();
    
    // Show uploading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading...'), backgroundColor: Colors.orange),
    );
    
    String? fileUrl = await storageService.uploadDocument(
      authVM.currentUserId!, 
      documentType, 
      file
    );
    
    if (fileUrl != null && mounted) {
      setState(() {
        if (type == 'CV') _cvUrl = fileUrl;
        else if (type == 'Academic Transcript') _academicUrl = fileUrl;
        else if (type == 'Matric Results') _matricUrl = fileUrl;
        else _idUrl = fileUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type uploaded!'), backgroundColor: AppTheme.success),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix errors above'), backgroundColor: Colors.red),
      );
      return;
    }

    final moduleError = AppValidators.validateModulesAreDifferent(
      _firstName!,
      _secondName,
      _hasSecondModule,
    );
    if (moduleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(moduleError), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_eligibilityConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must confirm eligibility'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final authVM = context.read<AuthViewModel>();
    final appVM = context.read<ApplicationViewModel>();
    
    if (authVM.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again'), backgroundColor: Colors.red),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final application = ApplicationModel(
      id: widget.application?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: authVM.currentUserId!,
      studentNumber: authVM.currentStudentNumber,
      fullName: authVM.currentStudentName,
      email: authVM.currentUserEmail!,
      yearOfStudy: authVM.currentYearOfStudy,
      firstModuleLevel: _firstLevel!,
      firstModuleName: _firstName!,
      firstModuleReason: _firstReasonController.text,
      hasSecondModule: _hasSecondModule,
      secondModuleLevel: _hasSecondModule ? _secondLevel : null,
      secondModuleName: _hasSecondModule ? _secondName : null,
      secondModuleReason: _hasSecondModule ? _secondReasonController.text : null,
      cvUrl: _cvUrl.isNotEmpty ? _cvUrl : null,
      academicTranscriptUrl: _academicUrl.isNotEmpty ? _academicUrl : null,
      matricResultsUrl: _matricUrl.isNotEmpty ? _matricUrl : null,
      idDocumentUrl: _idUrl.isNotEmpty ? _idUrl : null,
      eligibilityConfirmed: _eligibilityConfirmed,
      status: 'pending',
      rejectionReason: null,
      createdAt: widget.application?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (widget.application != null) {
      success = await appVM.updateApplication(application);
    } else {
      if (appVM.hasPendingApplication) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already have a pending application'), backgroundColor: Colors.red),
        );
        setState(() => _isSubmitting = false);
        return;
      }
      success = await appVM.submitApplication(application);
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.application != null ? 'Application updated!' : 'Application submitted!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appVM.errorMessage ?? 'Submission failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.application != null ? 'Edit Application' : 'New Application'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Student Info Card
                  Card(
                    color: AppTheme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Student Information', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Name: ${authVM.currentStudentName}'),
                          Text('Student Number: ${authVM.currentStudentNumber}'),
                          Text('Year of Study: ${authVM.currentYearOfStudy}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // First Module Section
                  _buildSectionHeader('First Module', required: true),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Module Level *', border: OutlineInputBorder()),
                    value: _firstLevel,
                    items: _levels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _firstLevel = v),
                    validator: (v) => AppValidators.validateModuleLevel(v),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Module Name *', border: OutlineInputBorder()),
                    value: _firstName,
                    items: _modules.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _firstName = v),
                    validator: (v) => AppValidators.validateModuleName(v, 'first'),
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: _firstReasonController,
                    decoration: const InputDecoration(labelText: 'Reason *', border: OutlineInputBorder()),
                    maxLines: 4,
                    validator: (v) => AppValidators.validateModuleReason(v, _firstName ?? 'module'),
                  ),
                  const SizedBox(height: 24),
                  
                  // Second Module (Optional)
                  _buildSectionHeader('Second Module (Optional)'),
                  const SizedBox(height: 8),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Apply for a second module'),
                      subtitle: const Text('Maximum of two modules per student'),
                      value: _hasSecondModule,
                      onChanged: (v) => setState(() => _hasSecondModule = v),
                      activeColor: AppTheme.accent,
                    ),
                  ),
                  
                  if (_hasSecondModule) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Second Module Level', border: OutlineInputBorder()),
                      value: _secondLevel,
                      items: _levels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _secondLevel = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Second Module Name', border: OutlineInputBorder()),
                      value: _secondName,
                      items: _modules.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _secondName = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _secondReasonController,
                      decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // Documents Section
                  _buildSectionHeader('Supporting Documents', required: true),
                  const SizedBox(height: 16),
                  _buildUploadButton('CV / Resume', _cvUrl, () => _pickFile('CV', 'cv')),
                  const SizedBox(height: 12),
                  _buildUploadButton('Academic Transcript', _academicUrl, () => _pickFile('Academic Transcript', 'academic_transcript')),
                  const SizedBox(height: 12),
                  _buildUploadButton('Matric Results', _matricUrl, () => _pickFile('Matric Results', 'matric_results')),
                  const SizedBox(height: 12),
                  _buildUploadButton('ID Document', _idUrl, () => _pickFile('ID Document', 'id_document')),
                  const SizedBox(height: 24),
                  
                  // Eligibility
                  _buildSectionHeader('Eligibility Confirmation', required: true),
                  const SizedBox(height: 8),
                  Card(
                    color: _eligibilityConfirmed ? AppTheme.success.withValues(alpha: 0.1) : null,
                    child: CheckboxListTile(
                      title: const Text('I confirm that I meet the eligibility requirements'),
                      subtitle: const Text('Good academic standing, no disciplinary issues, availability required'),
                      value: _eligibilityConfirmed,
                      onChanged: (v) => setState(() => _eligibilityConfirmed = v ?? false),
                      activeColor: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.application != null ? 'UPDATE APPLICATION' : 'SUBMIT APPLICATION'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool required = false}) {
    return Row(
      children: [
        Container(width: 4, height: 24, color: AppTheme.accent),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (required) const Text(' *', style: TextStyle(color: Colors.red)),
      ],
    );
  }

  Widget _buildUploadButton(String title, String fileUrl, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.upload_file),
      label: Text(fileUrl.isNotEmpty ? '✓ $title uploaded' : 'Upload $title'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: fileUrl.isNotEmpty ? AppTheme.success : Colors.grey),
        foregroundColor: fileUrl.isNotEmpty ? AppTheme.success : null,
      ),
    );
  }
}