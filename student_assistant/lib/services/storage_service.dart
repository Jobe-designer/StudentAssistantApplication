// lib/services/storage_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../config/supabase_config.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Document types
  static const Map<String, String> documentTypes = {
    'cv': 'CV',
    'academic_transcript': 'Academic Transcript',
    'matric_results': 'Matric Results',
    'id_document': 'ID Document',
  };

  // =============================================
  // UPLOAD DOCUMENT (Works with File)
  // =============================================
  Future<String?> uploadDocument(String userId, String documentType, File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '$userId/$documentType/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      debugPrint('📤 Uploading to bucket: ${SupabaseConfig.documentsBucket}');
      debugPrint('📤 File name: $fileName');

      await _supabase.storage
          .from(SupabaseConfig.documentsBucket)
          .upload(fileName, file);

      final publicUrl = _supabase.storage
          .from(SupabaseConfig.documentsBucket)
          .getPublicUrl(fileName);
      
      debugPrint('✅ Upload successful!');
      debugPrint('📎 Public URL: $publicUrl');
      
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Upload document error: $e');
      return null;
    }
  }

  // =============================================
  // UPLOAD DOCUMENT FROM XFile (Web compatibility)
  // =============================================
  Future<String?> uploadXFile(String userId, String documentType, XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.path.split('.').last;
      final fileName = '$userId/$documentType/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage
          .from(SupabaseConfig.documentsBucket)
          .uploadBinary(fileName, bytes);

      final publicUrl = _supabase.storage
          .from(SupabaseConfig.documentsBucket)
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Upload XFile error: $e');
      return null;
    }
  }

  // =============================================
  // UPLOAD PROFILE PICTURE
  // =============================================
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage
          .from(SupabaseConfig.profilesBucket)
          .upload(fileName, imageFile);

      return _supabase.storage
          .from(SupabaseConfig.profilesBucket)
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Upload profile picture error: $e');
      return null;
    }
  }

  // =============================================
  // PICK IMAGE (for profile picture)
  // =============================================
  static Future<XFile?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      return pickedFile;
    } catch (e) {
      return null;
    }
  }

  // =============================================
  // PICK FILE (for documents)
  // =============================================
  static Future<XFile?> pickDocument() async {
    final picker = ImagePicker();
    try {
      // For documents, we need to use FilePicker
      // This is handled in the UI layer with file_picker
      return null;
    } catch (e) {
      return null;
    }
  }
}