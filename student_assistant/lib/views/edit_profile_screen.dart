import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/auth_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final _formKey =
      GlobalKey<FormState>();

  late TextEditingController
      _fullNameController;

  late TextEditingController
      _phoneController;

  late TextEditingController
      _departmentController;

  late TextEditingController
      _yearController;

  bool _isSaving = false;
  Uint8List? _selectedImageBytes;

final ImagePicker _picker =
    ImagePicker();

  final _supabase =
      Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    final profile =
        context.read<AuthViewModel>().profile;

    _fullNameController =
        TextEditingController(
      text: profile?.fullName ?? '',
    );

    _phoneController =
        TextEditingController(
      text:
          profile?.phoneNumber ?? '',
    );

    _departmentController =
        TextEditingController(
      text:
          profile?.department ?? '',
    );

    _yearController =
        TextEditingController(
      text:
          profile?.yearOfStudy ?? '',
    );
  }
Future<void> _pickImage() async {
  try {
    final image =
        await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    final bytes =
        await image.readAsBytes();

    setState(() {
      _selectedImageBytes = bytes;
    });

  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text('Image error: $e'),
      ),
    );
  }
}
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authVM =
          context.read<AuthViewModel>();

      final userId =
          _supabase.auth.currentUser!.id;
final currentProfile =
    context.read<AuthViewModel>()
        .profile;

String? avatarUrl =
    currentProfile?.avatarUrl;

if (_selectedImageBytes != null) {
  final fileName =
      'profile_${DateTime.now().millisecondsSinceEpoch}.png';

  await _supabase.storage
      .from('student_profiles')
      .uploadBinary(
        fileName,
        _selectedImageBytes!,
      );

  avatarUrl = _supabase.storage
      .from('student_profiles')
      .getPublicUrl(fileName);
}
      await _supabase
          .from('profiles')
          .update({
        'full_name':
            _fullNameController.text
                .trim(),

        'phone_number':
            _phoneController.text
                .trim(),

        'department':
            _departmentController.text
                .trim(),

        'year_of_study':
            _yearController.text
                .trim(),
                'avatar_url': avatarUrl,
      }).eq('id', userId);

      await authVM.fetchProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Error: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildField({
    required String label,
    required TextEditingController
        controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 18,
      ),

      child: TextFormField(
        controller: controller,
        maxLines: maxLines,

        validator: (value) {
          if (value == null ||
              value.trim().isEmpty) {
            return '$label is required';
          }

          return null;
        },

        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        context.watch<AuthViewModel>()
            .profile;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        title:
            const Text('Edit Profile'),
      ),
body: SingleChildScrollView(
  padding: const EdgeInsets.all(20),

  child: Column(
    children: [
      // PROFILE HEADER
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Colors.indigo,
              Colors.blue,
            ],
          ),

          borderRadius:
              BorderRadius.circular(28),

          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),

        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,

              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,

                    backgroundColor:
                        Colors.white24,

                    backgroundImage:
                        _selectedImageBytes !=
                                null
                            ? MemoryImage(
                                _selectedImageBytes!,
                              ) as ImageProvider<Object>

                            : profile?.avatarUrl !=
                                    null
                                ? NetworkImage(
                                    profile!
                                        .avatarUrl!,
                                  ) as ImageProvider<Object>

                                : null,

                    child:
                        _selectedImageBytes ==
                                    null &&
                                profile?.avatarUrl ==
                                    null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,

                    child: Container(
                      padding:
                          const EdgeInsets.all(
                        8,
                      ),

                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Text(
              profile?.fullName ??
                  'Unknown User',

              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              profile?.email ??
                  'No Email',

              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),

      // FORM CARD
      Container(
        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(28),

          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              _buildField(
                label: 'Full Name',
                controller:
                    _fullNameController,
              ),

              _buildField(
                label: 'Phone Number',
                controller:
                    _phoneController,
              ),

              _buildField(
                label: 'Department',
                controller:
                    _departmentController,
              ),

              _buildField(
                label: 'Year of Study',
                controller:
                    _yearController,
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed:
                      _isSaving
                          ? null
                          : _saveProfile,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.indigo,

                    foregroundColor:
                        Colors.white,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 18,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                  ),

                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,

                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )

                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
    );
  }
}