import 'user_model.dart';

class AuthResponseModel {
  final String accessToken;
  final String? refreshToken;
  final String? deviceToken;
  final String? sessionId;
  final UserModel? user;

  const AuthResponseModel({
    required this.accessToken,
    this.refreshToken,
    this.deviceToken,
    this.sessionId,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return AuthResponseModel(
      accessToken:
          (json['access_token'] ?? json['accessToken'] ?? '').toString(),
      refreshToken: (json['refresh_token'] ?? json['refreshToken'])?.toString(),
      deviceToken: (json['device_token'] ?? json['deviceToken'])?.toString(),
      sessionId: (json['session_id'] ?? json['sessionId'])?.toString(),
      user: userJson is Map
          ? UserModel.fromJson(Map<String, dynamic>.from(userJson))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'device_token': deviceToken,
        'session_id': sessionId,
        'user': user?.toJson(),
      };
}
