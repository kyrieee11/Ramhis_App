import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:ramhis_app/core/session_manager.dart';

class AccUsernameWidget extends StatefulWidget {
  const AccUsernameWidget({
    super.key,
    required this.userData,
  });

  final Map<String, dynamic> userData;

  @override
  State<AccUsernameWidget> createState() => _AccUsernameWidgetState();
}

class _AccUsernameWidgetState extends State<AccUsernameWidget> {
  late final TextEditingController fullNameController;
  late final TextEditingController emailController;
  late final TextEditingController birthdateController;
  late final TextEditingController contactController;

  bool isSaving = false;
  bool isUploadingImage = false;

  File? selectedImage;
  String profileImageUrl = '';

  @override
  void initState() {
    super.initState();

    fullNameController = TextEditingController(
      text: (widget.userData['full_name'] ?? '').toString(),
    );
    emailController = TextEditingController(
      text: (widget.userData['email'] ?? '').toString(),
    );
    birthdateController = TextEditingController(
      text: (widget.userData['birthdate'] ?? '').toString(),
    );
    contactController = TextEditingController(
      text: (widget.userData['contact_number'] ?? '').toString(),
    );
    profileImageUrl = (widget.userData['profile_image_url'] ?? '').toString();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    birthdateController.dispose();
    contactController.dispose();
    super.dispose();
  }

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'http://10.0.2.2:5000$url';
  }

  Future<File?> _cropImage(String imagePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: imagePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: const Color(0xFF3F5FBE),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF3F5FBE),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Profile Picture',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (cropped == null) return null;
    return File(cropped.path);
  }

  Future<void> _pickAndUploadImage() async {
    final userId = (widget.userData['_id'] ?? '').toString();

    if (userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User id is missing')),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;

    final croppedFile = await _cropImage(picked.path);
    if (croppedFile == null) return;

    if (!mounted) return;
    setState(() {
      selectedImage = croppedFile;
      isUploadingImage = true;
    });

    try {
      final bytes = await croppedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.put(
  Uri.parse('${AuthSession.baseUrl}/users/$userId/profile-image'),
  headers: AuthSession.headers(),
  body: jsonEncode({
    'imageBase64': base64Image,
    'fileName': croppedFile.path.split('/').last,
  }),
);

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data != null) {
        setState(() {
          profileImageUrl = (data['imageUrl'] ?? '').toString();
        });

        if (data['user'] is Map) {
         AuthSession.currentUser =
    Map<String, dynamic>.from(data['user']);
          
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (data?['message'] ?? 'Image upload failed').toString(),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final userId = (widget.userData['_id'] ?? '').toString();

    if (userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User id is missing')),
      );
      return;
    }

    if (fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        birthdateController.text.trim().isEmpty ||
        contactController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => isSaving = true);

    try {
      final response = await http.put(
  Uri.parse('${AuthSession.baseUrl}/users/$userId'),
  headers: AuthSession.headers(),
  body: jsonEncode({
    'full_name': fullNameController.text.trim(),
    'email': emailController.text.trim(),
    'contact_number': contactController.text.trim(),
    'birthdate': birthdateController.text.trim(),
  }),
);

     final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (data != null && data['user'] is Map) {
          AuthSession.currentUser =
    Map<String, dynamic>.from(data['user']);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((data?['message'] ?? 'Update failed').toString()),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  InputDecoration _input(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildAvatar() {
    ImageProvider? provider;

    if (selectedImage != null) {
      provider = FileImage(selectedImage!);
    } else if (profileImageUrl.isNotEmpty) {
      provider = NetworkImage(_resolveImageUrl(profileImageUrl));
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: provider,
          child: provider == null
              ? const Icon(
                  Icons.person,
                  size: 40,
                  color: Color(0xFF3F5FBE),
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: InkWell(
            onTap: isUploadingImage ? null : _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF3F5FBE),
                shape: BoxShape.circle,
              ),
              child: isUploadingImage
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F9),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B2559),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 20),
            TextField(
              controller: fullNameController,
              decoration: _input('Full Name', Icons.person),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: _input('Email', Icons.email),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: birthdateController,
              decoration: _input('Birthdate', Icons.cake),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contactController,
              decoration: _input('Contact Number', Icons.phone),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSaving ? null : _save,
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}