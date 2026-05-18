enum UserRole { student, admin }

class UserProfile {
  final String id;
  final String fullName;
  final String userNumber;
  final UserRole role;
  final String? email;

  final String? phoneNumber;
  final String? department;
  final String? yearOfStudy;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.userNumber,
    required this.role,
    this.email,
    this.phoneNumber,
    this.department,
    this.yearOfStudy,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'],
      userNumber: json['user_number'],

      role: json['role'] == 'admin'
          ? UserRole.admin
          : UserRole.student,

      email: json['email'],

      phoneNumber: json['phone_number'],
      department: json['department'],
      yearOfStudy: json['year_of_study'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'user_number': userNumber,

      'role':
          role.toString().split('.').last,

      'email': email,

      'phone_number': phoneNumber,
      'department': department,
      'year_of_study': yearOfStudy,
      'avatar_url': avatarUrl,
    };
  }
}