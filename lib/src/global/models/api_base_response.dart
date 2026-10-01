// To parse this JSON data, do
//
//     final apiBaseResponse = apiBaseResponseFromJson(jsonString);

import 'dart:convert';

import 'package:bs_mobile/index.dart';

ApiBaseResponse apiBaseResponseFromJson(String str) =>
    ApiBaseResponse.fromJson(json.decode(str));

String apiBaseResponseToJson(ApiBaseResponse data) =>
    json.encode(data.toJson());

class ApiBaseResponse {
  int? messageCode;
  bool? isSuccess;
  String? messageStatus;
  String? messageText;
  bool? isUpdateAvailable;
  bool? isForceUpdate;
  String? eventType;

  ApiBaseResponse({
    this.messageCode,
    this.messageStatus,
    this.isSuccess,
    this.messageText,
    this.eventType,
    this.isUpdateAvailable,
    this.isForceUpdate,
  });

  factory ApiBaseResponse.fromJson(Map<String, dynamic> json) =>
      ApiBaseResponse(
        messageCode: Parse.parseInt(json["message_code"]),
        messageStatus: Parse.parseString(json["message_status"]),
        isSuccess: Parse.parseBool(json["is_success"]),
        messageText: Parse.parseString(json["message_text"]),
        isUpdateAvailable: Parse.parseBool(json["isUpdated"]),
        isForceUpdate: Parse.parseBool(json["is_force_update"]),
      );

  Map<String, dynamic> toJson() => {
    "message_code": messageCode,
    "message_status": messageStatus,
    "is_success": isSuccess,
    "message_text": messageText,
    "is_update_available": isUpdateAvailable,
    "is_force_update": isForceUpdate,
  };
}
