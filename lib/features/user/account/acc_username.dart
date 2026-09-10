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

const _kNavy = Color(0xFF123F91);
const _kNavyDark = Color(0xFF082B6B);
const _kGold = Color(0xFFD9C27A);
const _kGoldDark = Color(0xFF9D7D2F);
const _kCream = Color(0xFFF7F2E5);
const _kInk = Color(0xFF24304A);
const _kMuted = Color(0xFF6F7480);

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
      fillColor: _kCream.withValues(alpha: 0.92),
      prefixIcon: Container(
        margin: const EdgeInsets.all(7),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kNavy, _kNavyDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kGold, width: 1.1),
        ),
        child: Icon(icon, color: _kCream, size: 25),
      ),
      hintStyle: const TextStyle(
        color: _kMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: _kGoldDark,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: _kNavy,
          width: 1.6,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kCream,
            border: Border.all(color: _kGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: _kCream,
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
            color: _kGold,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isUploadingImage ? null : _pickAndUploadImage,
              child: SizedBox(
                width: 52,
                height: 52,
                child: isUploadingImage
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kNavy,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: _kNavy,
                        size: 25,
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
      padding: const EdgeInsets.only(left: 8, bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          color: _kInk,
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
            fontSize: 17,
            fontWeight: FontWeight.w500,
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
                child: Column(
                  children: [
                    _buildPhotoHero(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                      child: _buildForm(),
                    ),
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
      height: 66,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavy, _kNavyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: _kGold, width: 1.3),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 54,
                height: 54,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _kGold,
                  size: 21,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kCream,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
          SizedBox(
            width: 66,
            child: TextButton(
              onPressed: isSaving
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: _kCream,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _kGold,
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isEditing
                                        ? 'Save Changes?'
                                        : 'Edit Profile?',
                                    style: const TextStyle(
                                      color: _kInk,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    isEditing
                                        ? 'Do you want to save your profile changes?'
                                        : 'Do you want to edit your profile?',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _kMuted,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
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
                                            foregroundColor: _kCream,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                  color: _kCream,
                  fontSize: 15,
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
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavy, _kNavyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: _kGold, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 10),
          const Text(
            'Change Photo',
            style: TextStyle(
              color: _kCream,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 14),
          child: Text(
            'Personal Information',
            style: TextStyle(
              color: _kInk,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 7),
          decoration: BoxDecoration(
            color: _kCream.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: _kGoldDark, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _formField(
                label: 'Full Name',
                controller: fullNameController,
                icon: Icons.person_rounded,
                hint: 'Enter full name',
                keyboardType: TextInputType.name,
                readOnly: !isEditing,
              ),
              const SizedBox(height: 13),
              _formField(
                label: 'Email',
                controller: emailController,
                icon: Icons.email_rounded,
                hint: 'Enter email address',
                keyboardType: TextInputType.emailAddress,
                readOnly: !isEditing,
              ),
              const SizedBox(height: 13),
              _formField(
                label: 'Birthdate',
                controller: birthdateController,
                icon: Icons.cake_rounded,
                hint: 'Select birthdate',
                readOnly: !isEditing,
                onTap: isEditing ? _showBirthdatePicker : null,
              ),
              const SizedBox(height: 13),
              _formField(
                label: 'Contact Number',
                controller: contactController,
                icon: Icons.phone_rounded,
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
        ),
      ],
    );
  }
}

class _MarbleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = _kCream;
    canvas.drawRect(Offset.zero & size, base);

    final vein = Paint()
      ..color = const Color(0xFF9EA9B8).withValues(alpha: 0.27)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final soft = Paint()
      ..color = const Color(0xFFBDC5D0).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    final paths = [
      Path()
        ..moveTo(size.width * .06, size.height * .02)
        ..cubicTo(size.width * .30, size.height * .12,
            size.width * .12, size.height * .24,
            size.width * .42, size.height * .34)
        ..cubicTo(size.width * .60, size.height * .42,
            size.width * .37, size.height * .56,
            size.width * .66, size.height * .68)
        ..cubicTo(size.width * .82, size.height * .76,
            size.width * .62, size.height * .91,
            size.width * .93, size.height),
      Path()
        ..moveTo(size.width * .93, size.height * .03)
        ..cubicTo(size.width * .73, size.height * .15,
            size.width * .88, size.height * .28,
            size.width * .64, size.height * .40)
        ..cubicTo(size.width * .48, size.height * .49,
            size.width * .72, size.height * .60,
            size.width * .44, size.height * .80),
    ];

    for (final path in paths) {
      canvas.drawPath(path, vein);
    }

    canvas.drawPath(
      Path()
        ..moveTo(size.width * .02, size.height * .18)
        ..cubicTo(size.width * .27, size.height * .22,
            size.width * .12, size.height * .33,
            size.width * .45, size.height * .39)
        ..cubicTo(size.width * .66, size.height * .45,
            size.width * .42, size.height * .57,
            size.width * .73, size.height * .66),
      soft,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
