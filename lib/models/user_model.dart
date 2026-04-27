class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String accountType;
  final String contactNumber;
  final String birthdate;
  final String profileImageUrl;
  final String status;
  final bool isVerified;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.accountType,
    required this.contactNumber,
    required this.birthdate,
    required this.profileImageUrl,
    required this.status,
    required this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      accountType: (json['account_type'] ?? '').toString(),
      contactNumber: (json['contact_number'] ?? '').toString(),
      birthdate: (json['birthdate'] ?? '').toString(),
      profileImageUrl: (json['profile_image_url'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      isVerified: (json['is_verified'] ?? false) == true,
    );
  }
}