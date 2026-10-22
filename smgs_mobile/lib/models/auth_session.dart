import 'experience.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.email,
    required this.fullName,
    required this.role,
  });
  final String accessToken, email, fullName, role;
  final DateTime expiresAt;
  bool get isExpired => !expiresAt.isAfter(DateTime.now().toUtc());

  static const roles = {
    'Visitor': UserRole.visitor,
    'Admin': UserRole.administrator,
    'Museum Staff': UserRole.museumStaff,
    'Staff': UserRole.systemStaff,
    'Curator': UserRole.curator,
  };

  VisitorUser get user =>
      VisitorUser(name: fullName, email: email, role: roles[role]!);

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'];
    final email = json['email'];
    final name = json['fullName'];
    final expiry = DateTime.tryParse(
      json['accessTokenExpiration']?.toString() ?? '',
    )?.toUtc();
    final assigned = json['roles'];
    if (token is! String ||
        token.isEmpty ||
        email is! String ||
        email.isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        expiry == null ||
        !expiry.isAfter(DateTime.now().toUtc()) ||
        assigned is! List ||
        assigned.length != 1 ||
        !roles.containsKey(assigned.single)) {
      throw const FormatException(
        'Phiên đăng nhập từ máy chủ không hợp lệ hoặc đã hết hạn.',
      );
    }
    return AuthSession(
      accessToken: token,
      expiresAt: expiry,
      email: email,
      fullName: name,
      role: assigned.single as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'accessTokenExpiration': expiresAt.toIso8601String(),
    'email': email,
    'fullName': fullName,
    'roles': [role],
  };
}
