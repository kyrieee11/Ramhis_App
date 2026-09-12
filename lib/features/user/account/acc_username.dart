import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:ramhis_app/core/app_config.dart';
import 'package:ramhis_app/features/user/widgets/bottom_nav.dart';

import 'package:ramhis_app/core/session_manager.dart';

const _kNavy = Color(0xFF10539B);
const _kNavyDark = Color(0xFF0B4380);
const _kGold = Color(0xFFE3F2FD);
const _kLightBlue = Color(0xFFE3F2FD);
const _kGoldDark = Color(0xFFCDE1EC);
const _kCream = Color(0xFFF8FAFC);
const _kInk = Color(0xFF102A43);
const _kMuted = Color(0xFF8292A6);
const _kBlue = Color(0xFF1863B5);
const _kSoftBlue = Color(0xFFEBF3FA);
const _kSuccess = Color(0xFF22A06B);

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
  bool isEditing = false;

  String _origFullName = '';
  String _origEmail = '';
  String _origBirthdate = '';
  String _origContact = '';

  File? selectedImage;
  String profileImageUrl = '';

  String _readValue(List<String> keys) {
  final sources = <Map<String, dynamic>>[
    widget.userData,
    if (AuthSession.currentUser != null) AuthSession.currentUser!,
    if (widget.userData['user'] is Map)
      Map<String, dynamic>.from(widget.userData['user']),
    if (widget.userData['data'] is Map)
      Map<String, dynamic>.from(widget.userData['data']),
  ];

  for (final source in sources) {
    for (final key in keys) {
      final value = source[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
  }

  return '';
}

  String get _currentUserId {
    final value = widget.userData['_id'] ??
        widget.userData['id'] ??
        widget.userData['userId'] ??
        AuthSession.currentUser?['_id'] ??
        AuthSession.currentUser?['id'] ??
        AuthSession.currentUser?['userId'] ??
        '';

    return value.toString().trim();
  }

  String _userApiUrl(String userId) {
    final base = AppConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');

    if (base.endsWith('/api')) {
      return '$base/users/$userId';
    }

    return '$base/api/users/$userId';
  }

  Map<String, dynamic> _decodeJsonMap(http.Response response) {
    final body = response.body.trim();

    debugPrint('PROFILE URL: ${response.request?.url}');
    debugPrint('PROFILE STATUS: ${response.statusCode}');
    debugPrint('PROFILE BODY: $body');

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    if (!body.startsWith('{') && !body.startsWith('[')) {
      throw FormatException(
        'Backend returned non-JSON. Check API URL: ${response.request?.url}',
      );
    }

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }

  @override
  void initState() {
    super.initState();

    fullNameController = TextEditingController(
      text: _readValue([
        'full_name',
        'fullName',
        'name',
        'username',
      ]),
    );

    emailController = TextEditingController(
      text: _readValue([
        'email',
      ]),
    );

    birthdateController = TextEditingController(
      text: _readValue([
        'birthdate',
        'birthDate',
        'bdate',
        'dateOfBirth',
      ]),
    );

    contactController = TextEditingController(
      text: _readValue([
        'contact_number',
        'contactNumber',
        'phone',
        'phoneNumber',
        'mobile',
      ]),
    );

    profileImageUrl = _readValue([
      'profile_image_url',
      'profileImageUrl',
      'profileImage',
      'imageUrl',
      'avatar',
    ]);
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
  final cleanUrl = url.trim();

  if (cleanUrl.isEmpty) return '';

  if (cleanUrl.startsWith('http://') ||
      cleanUrl.startsWith('https://')) {
    return cleanUrl;
  }

  if (cleanUrl.startsWith('/')) {
    return '${AppConfig.baseUrl}$cleanUrl';
  }

  return '${AppConfig.baseUrl}/$cleanUrl';
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
          toolbarColor: _kNavy,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: _kNavy,
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
    final userId = _currentUserId;

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
 Uri.parse('${AppConfig.baseUrl}/users/$userId'),
  headers: {
    ...AuthSession.headers(),
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'imageBase64': base64Image,
    'fileName': croppedFile.path.split('/').last,
  }),
);

      final data = _decodeJsonMap(response);

      if (!mounted) return;

      if (response.statusCode == 200 && data != null) {
        setState(() {
          profileImageUrl = (
            data['imageUrl'] ??
                data['profile_image_url'] ??
                data['profileImageUrl'] ??
                profileImageUrl
          ).toString();
        });

        if (data['user'] is Map) {
          await AuthSession.updateCurrentUser(
            Map<String, dynamic>.from(data['user']),
          );
        } else {
          await AuthSession.updateCurrentUser({
            'profile_image_url': profileImageUrl,
            'profileImageUrl': profileImageUrl,
            'profileImage': profileImageUrl,
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (data['message'] ?? 'Image upload failed').toString(),
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

  void _enterEditMode() {
    _origFullName = fullNameController.text;
    _origEmail = emailController.text;
    _origBirthdate = birthdateController.text;
    _origContact = contactController.text;

    setState(() {
      isEditing = true;
    });
  }

  void _cancelEdit() {
    fullNameController.text = _origFullName;
    emailController.text = _origEmail;
    birthdateController.text = _origBirthdate;
    contactController.text = _origContact;

    setState(() {
      isEditing = false;
    });
  }
  

  Future<void> _save() async {
    final userId = _currentUserId;

    if (userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User id is missing')),
      );
      return;
    }

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final birthdate = birthdateController.text.trim();
    final contactNumber = contactController.text.trim();

    final isValidContact =
    RegExp(r'^09\d{9}$').hasMatch(contactNumber);

if (!isValidContact) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Please enter a valid 11-digit contact number starting with 09',
      ),
    ),
  );

  return;
}

    if (!mounted) return;
    setState(() => isSaving = true);

    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/users/$userId'),
        headers: {
          ...AuthSession.headers(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'full_name': fullName,
          'fullName': fullName,
          'name': fullName,
          'email': email,
          'contact_number': contactNumber,
          'contactNumber': contactNumber,
          'phone': contactNumber,
          'birthdate': birthdate,
          'birthDate': birthdate,
          'bdate': birthdate,
        }),
      );

      final data = _decodeJsonMap(response);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final updatedUser = {
          ...?AuthSession.currentUser,
          '_id': userId,
          'id': userId,
          'name': fullName,
          'full_name': fullName,
          'email': email,
          'birthdate': birthdate,
          'birthDate': birthdate,
          'birthday': birthdate,
          'bdate': birthdate,
          'contact_number': contactNumber,
          'contactNumber': contactNumber,
          'phone': contactNumber,
          'phoneNumber': contactNumber,
          'profileImage': profileImageUrl,
          'profileImageUrl': profileImageUrl,
          'profile_image_url': profileImageUrl,
          'avatar': profileImageUrl,
        };

        AuthSession.currentUser = updatedUser;

        if (!mounted) return;

        setState(() {
          isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
          ),
        );
      } else {
        final message = data['message']?.toString().trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message != null && message.isNotEmpty
                  ? message
                  : 'Failed to save profile. Please try again.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      final rawMessage = error.toString();
      final friendlyMessage = rawMessage
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', '')
          .trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyMessage.isNotEmpty
                ? friendlyMessage
                : 'Unable to save profile. Please try again.',
          ),
        ),
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
      prefixIcon: Container(
        margin: const EdgeInsets.all(3),
        width: 48,
        decoration: BoxDecoration(
          color: _kSoftBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: _kNavy,
          size: 23,
        ),
      ),
      hintStyle: const TextStyle(
        color: _kMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 17,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: _kGoldDark,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: _kNavy,
          width: 2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: _kGoldDark,
          width: 1.5,
        ),
      ),
      counterText: '',
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
            color: Colors.white,
            border: Border.all(
              color: _kLightBlue,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _kNavy.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: _kSoftBlue,
            backgroundImage: provider,
            child: provider == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 54,
                    color: _kNavy,
                  )
                : null,
          ),
        ),
        Positioned(
          right: -2,
          bottom: 2,
          child: Material(
            color: _kNavy,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isUploadingImage ? null : _pickAndUploadImage,
              child: SizedBox(
                width: 48,
                height: 48,
                child: isUploadingImage
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatBirthdate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  DateTime _initialBirthdate() {
    final raw = birthdateController.text.trim();

    if (raw.isEmpty) return DateTime(2000, 1, 1);

    final parsedIso = DateTime.tryParse(raw);
    if (parsedIso != null) return parsedIso;

    final parts = raw.replaceAll(',', '').split(' ');

    if (parts.length == 3) {
      const months = {
        'january': 1, 'february': 2, 'march': 3, 'april': 4,
        'may': 5, 'june': 6, 'july': 7, 'august': 8,
        'september': 9, 'october': 10, 'november': 11, 'december': 12,
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
              primary: _kNavy,
              onPrimary: _kCream,
              surface: _kCream,
              onSurface: _kInk,
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
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          color: _kInk,
          fontSize: 14,
          fontWeight: FontWeight.w800,
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
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
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
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          style: const TextStyle(
            color: _kInk,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: _input(hint, icon),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                child: Column(
                  children: [
                    _buildPhotoHero(),
                    const SizedBox(height: 16),
                    _buildForm(),
                  ],
                ),
              ),
            ),
            const CustomNavBar(currentIndex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 62,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavy, _kNavyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 54,
                height: 54,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextButton(
              onPressed: isSaving
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return Dialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      color: _kSoftBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: _kNavy,
                                      size: 25,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    isEditing
                                        ? 'Save Changes?'
                                        : 'Edit Profile?',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _kInk,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isEditing
                                        ? 'Do you want to save your profile changes?'
                                        : 'Do you want to edit your profile?',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _kMuted,
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            if (isEditing) _cancelEdit();
                                          },
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: _kMuted,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            if (isEditing) {
                                              await _save();
                                            } else {
                                              _enterEditMode();
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _kNavy,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: Text(
                                            isEditing ? 'Save' : 'Edit',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
              child: Text(
                isSaving ? '...' : 'Edit',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kGoldDark),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 10),
          const Text(
            'Change Profile Photo',
            style: TextStyle(
              color: _kNavy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Tap the camera button to choose a new photo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _kGoldDark,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _kLightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: _kNavy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: TextStyle(
                        color: _kInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Update your profile details',
                      style: TextStyle(
                        color: _kMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _formField(
            label: 'Full Name',
            controller: fullNameController,
            icon: Icons.person_outline_rounded,
            hint: 'Enter full name',
            keyboardType: TextInputType.name,
            readOnly: !isEditing,
          ),
          const SizedBox(height: 17),
          _formField(
            label: 'Email',
            controller: emailController,
            icon: Icons.email_outlined,
            hint: 'Enter email address',
            keyboardType: TextInputType.emailAddress,
            readOnly: !isEditing,
          ),
          const SizedBox(height: 17),
          _formField(
            label: 'Birthdate',
            controller: birthdateController,
            icon: Icons.calendar_month_outlined,
            hint: 'Select birthdate',
            readOnly: !isEditing,
            onTap: isEditing ? _showBirthdatePicker : null,
          ),
          const SizedBox(height: 17),
          _formField(
            label: 'Contact Number',
            controller: contactController,
            icon: Icons.phone_outlined,
            hint: 'Enter contact number',
            keyboardType: TextInputType.number,
            readOnly: !isEditing,
            maxLength: 11,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ],
      ),
    );
  }
}
