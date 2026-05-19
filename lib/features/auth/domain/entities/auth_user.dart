class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    required this.isVerified,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isActive;
  final bool isVerified;
}




