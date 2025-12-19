enum UserRole { staff, leader, manager }

class User {
  final String id;
  final String name;
  final UserRole role;
  final String contact;
  final String? loginId;
  final String? password;

  User({
    required this.id,
    required this.name,
    required this.role,
    required this.contact,
    this.loginId,
    this.password,
  });
}
