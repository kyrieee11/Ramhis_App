class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String contactNumber;
  final String birthdate;
  final String profileImageUrl;
  final String accountType;
  final String role;
  final String status;
  final String specialty;
  final String department;
  final String organization;
  final String skills;
  final String prcLicenseNumber;
  final bool isVerified;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.contactNumber,
    required this.birthdate,
    required this.profileImageUrl,
    required this.accountType,
    required this.role,
    required this.status,
    required this.specialty,
    required this.department,
    required this.organization,
    required this.skills,
    required this.prcLicenseNumber,
    required this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      contactNumber: (json['contact_number'] ?? '').toString(),
      birthdate: (json['birthdate'] ?? '').toString(),
      profileImageUrl: (json['profile_image_url'] ?? '').toString(),
      accountType: (json['account_type'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      specialty: (json['specialty'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      organization: (json['organization'] ?? '').toString(),
      skills: (json['skills'] ?? '').toString(),
      prcLicenseNumber: (json['prc_license_number'] ?? '').toString(),
      isVerified: json['is_verified'] == true,
    );
  }
}