import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:ramhis_app/core/app_config.dart';

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
    return '${AppConfig.baseUrl}$url';
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
        Uri.parse('${AuthSession.baseUrl}/users/$userId'),
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
          AuthSession.currentUser = Map<String, dynamic>.from(data['user']);
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
        Uri.parse('${AppConfig.baseUrl}/users/$userId'),
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
          AuthSession.currentUser = Map<String, dynamic>.from(data['user']);
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
      fillColor: const Color(0xFFF9FAFF),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF5B76F7),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFB2BAD2),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE2E7F3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF5B76F7),
          width: 1.4,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE2E7F3),
          width: 1,
        ),
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
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5B76F7),
                Color(0xFF4564E8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4564E8).withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 52,
              backgroundColor: const Color(0xFFEAF0FF),
              backgroundImage: provider,
              child: provider == null
                  ? const Icon(
                      Icons.person,
                      size: 52,
                      color: Color(0xFF5B76F7),
                    )
                  : null,
            ),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: isUploadingImage ? null : _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFF4564E8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: isUploadingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatBirthdate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  DateTime _initialBirthdate() {
    final raw = birthdateController.text.trim();

    if (raw.isEmpty) {
      return DateTime(2000, 1, 1);
    }

    final parsedIso = DateTime.tryParse(raw);

    if (parsedIso != null) {
      return parsedIso;
    }

    final parts = raw.replaceAll(',', '').split(' ');

    if (parts.length == 3) {
      const months = {
        'january': 1,
        'february': 2,
        'march': 3,
        'april': 4,
        'may': 5,
        'june': 6,
        'july': 7,
        'august': 8,
        'september': 9,
        'october': 10,
        'november': 11,
        'december': 12,
      };

      final month = months[parts[0].toLowerCase()];
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime(2000, 1, 1);
  }

  Future<void> _showBirthdatePicker() async {
    FocusScope.of(context).unfocus();

    final picked = await showDatePicker(
      context: context,
      initialDate: _initialBirthdate(),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5B76F7),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1B2559),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      birthdateController.text = _formatBirthdate(picked);
    });
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF7B8BB2),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _formField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(
            color: Color(0xFF1B2559),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: _input(hint, icon),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: isSaving
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFF5B76F7),
                  Color(0xFF4564E8),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: isSaving ? const Color(0xFFB8C2EA) : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4564E8).withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF7B8BB2),
          side: const BorderSide(
            color: Color(0xFFD8DEEF),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF5B76F7),
                Color(0xFF4564E8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 42),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF5B76F7),
                    Color(0xFF4564E8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(34),
                  bottomRight: Radius.circular(34),
                ),
              ),
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 14),
                  const Text(
                    'Change Photo',
                    style: TextStyle(
                      color: Color(0xFFEAF0FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            color: Color(0xFF1B2559),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _formField(
                          label: 'Full Name',
                          controller: fullNameController,
                          icon: Icons.person_rounded,
                          hint: 'Enter full name',
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 16),
                        _formField(
                          label: 'Email',
                          controller: emailController,
                          icon: Icons.email_rounded,
                          hint: 'Enter email address',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _formField(
                          label: 'Birthdate',
                          controller: birthdateController,
                          icon: Icons.cake_rounded,
                          hint: 'Select birthdate',
                          readOnly: true,
                          onTap: _showBirthdatePicker,
                        ),
                        const SizedBox(height: 16),
                        _formField(
                          label: 'Contact Number',
                          controller: contactController,
                          icon: Icons.phone_rounded,
                          hint: 'Enter contact number',
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                  const SizedBox(height: 12),
                  _buildCancelButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}