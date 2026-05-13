class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

class RegisterRequest {
  final String username;
  final String password;
  final String confirmPassword;
  final String firstName;
  final String lastName;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'confirmPassword': confirmPassword,
        'firstName': firstName,
        'lastName': lastName,
      };
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        tokenType: json['tokenType'] as String? ?? 'Bearer',
      );
}
