import 'dart:convert';

AuthLoginRequest authLoginRequestFromJson(String str) =>
    AuthLoginRequest.fromJson(json.decode(str));

String authLoginRequestToJson(AuthLoginRequest data) =>
    json.encode(data.toJson());

class AuthLoginRequest {
  String applicationLicense;
  String username;
  String password;
  String platform;

  AuthLoginRequest({
    required this.applicationLicense,
    required this.username,
    required this.password,
    required this.platform,
  });

  factory AuthLoginRequest.fromJson(Map<String, dynamic> json) =>
      AuthLoginRequest(
        applicationLicense: json["application_license"],
        username: json["username"],
        password: json["password"],
        platform: json["platform"],
      );

  Map<String, dynamic> toJson() => {
    "application_license": applicationLicense,
    "username": username,
    "password": password,
    "platform": platform,
  };
}

AuthLoginResponse authLoginResponseFromJson(String str) =>
    AuthLoginResponse.fromJson(json.decode(str));

String authLoginResponseToJson(AuthLoginResponse data) =>
    json.encode(data.toJson());

class AuthLoginResponse {
  String messageCode;
  String messageText;
  Data data;

  AuthLoginResponse({
    required this.messageCode,
    required this.messageText,
    required this.data,
  });

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) =>
      AuthLoginResponse(
        messageCode: json["message_code"]?.toString() ?? '',
        messageText:
            json["message_text"]?.toString() ??
            json["message_status"]?.toString() ??
            '',
        data: json["data"] != null
            ? Data.fromJson(json["data"])
            : Data(accessToken: '', refreshToken: ''),
      );

  Map<String, dynamic> toJson() => {
    "message_code": messageCode,
    "message_text": messageText,
    "data": data.toJson(),
  };
}

class Data {
  String accessToken;
  String refreshToken;

  Data({required this.accessToken, required this.refreshToken});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    accessToken: json["access_token"],
    refreshToken: json["refresh_token"],
  );

  Map<String, dynamic> toJson() => {
    "access_token": accessToken,
    "refresh_token": refreshToken,
  };
}
