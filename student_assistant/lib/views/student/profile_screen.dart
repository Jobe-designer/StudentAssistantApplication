// lib/views/student/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:student_assistant/viewmodel/auth_viewmodel.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _yearController = TextEditingController();
  final _departmentController = TextEditingController();
  
  dynamic _selectedImage;  // ✅ Changed from File? to dynamic (accepts XFile or File)
  String? _profileImageUrl;
  String? _previewImageUrl;
  bool _isSaving = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _yearController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authVM = context.read<AuthViewModel>();
    final student = authVM.currentStudent;
    
    if (student != null) {
      _fullNameController.text = student.fullName;
      _phoneController.text = student.phoneNumber ?? '';
      _yearController.text = student.yearOfStudy.toString();
      _departmentController.text = student.department;
      _profileImageUrl = student.profilePictureUrl;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await StorageService.pickImage(source);
      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;  // This is either XFile (web) or File (mobile)
          _previewImageUrl = image.path;
          _uploadError = null;
        });
        print(' Image selected: ${image.path}');
        print(' Image type: ${image.runtimeType}');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      setState(() {
        _uploadError = 'Error picking image: $e';
      });
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.deepPurple),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
      _uploadError = null;
    });
    
    final authVM = context.read<AuthViewModel>();
    
    print('💾 Saving profile...');
    print('📸 Has new image: ${_selectedImage != null}');
    print('📸 Image type: ${_selectedImage?.runtimeType}');
    
    final success = await authVM.updateProfile(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      yearOfStudy: int.tryParse(_yearController.text),
      department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
      profileImage: _selectedImage,
    );
    
    if (mounted) {
      setState(() => _isSaving = false);
    }
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVM.errorMessage ?? 'Update failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final student = authVM.currentStudent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    _buildProfileImage(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          onPressed: _showImagePickerDialog,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_uploadError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _uploadError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Student Number (Read Only)
              TextFormField(
                initialValue: student?.studentNumber,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Student Number',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Email (Read Only)
              TextFormField(
                initialValue: student?.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: 'Optional',
                ),
              ),
              const SizedBox(height: 16),
              
              // Year of Study
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year of Study *',
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Year of study is required';
                  final year = int.tryParse(value);
                  if (year == null || year < 1 || year > 4) {
                    return 'Enter a valid year (1-4)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Department
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('SAVE CHANGES'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_selectedImage != null && _previewImageUrl != null) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.deepPurple[100],
        backgroundImage: NetworkImage(_previewImageUrl!),
        child: null,
      );
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.deepPurple[100],
        backgroundImage: NetworkImage(_profileImageUrl!),
        child: null,
      );
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.deepPurple[100],
        child: Text(
          _fullNameController.text.isNotEmpty
              ? _fullNameController.text[0].toUpperCase()
              : 'S',
          style: const TextStyle(fontSize: 40, color: Colors.deepPurple),
        ),
      );
    }
  }
}