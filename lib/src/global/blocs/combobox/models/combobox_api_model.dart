import 'dart:convert';

import 'package:bs_mobile/index.dart';

ComboboxResponse comboboxResponseFromJson(String str) =>
    ComboboxResponse.fromJson(json.decode(str));

String comboboxResponseToJson(ComboboxResponse data) =>
    json.encode(data.toJson());

class ComboboxResponse {
  final List<ComboboxModel> comboboxes;
  final String messageCode;
  final bool? isSuccess;
  final String? message;
  final int? totalRecords;
  final int? totalPages;

  const ComboboxResponse({
    this.comboboxes = const [],
    this.messageCode = '',
    this.isSuccess,
    this.message,
    this.totalRecords,
    this.totalPages,
  });

  bool get isOk => isSuccess == true && messageCode == '0';

  factory ComboboxResponse.fromJson(Map<String, dynamic> json) =>
      ComboboxResponse(
        comboboxes: json['comboboxes'] == null
            ? const []
            : List<ComboboxModel>.from(
                json['comboboxes'].map((x) => ComboboxModel.fromJson(x)),
              ),
        messageCode: json['message_code']?.toString() ?? '',
        isSuccess: json['is_success'] as bool?,
        message: json['message']?.toString(),
        totalRecords: Parse.parseInt(json['total_records']),
        totalPages: Parse.parseInt(json['total_pages']),
      );

  Map<String, dynamic> toJson() => {
    'comboboxes': List<dynamic>.from(comboboxes.map((x) => x.toJson())),
    'message_code': messageCode,
    'is_success': isSuccess,
    'message': message,
    'total_records': totalRecords,
    'total_pages': totalPages,
  };
}

class ComboboxModel {
  final String? description;
  final String? displayMember;
  final int? displaySequence;
  final bool? isActive;
  final String? valueMember;
  final String? valueMember1;
  final String? valueMember2;
  final String? valueMember3;

  const ComboboxModel({
    this.description,
    this.displayMember,
    this.displaySequence,
    this.isActive,
    this.valueMember,
    this.valueMember1,
    this.valueMember2,
    this.valueMember3,
  });

  factory ComboboxModel.fromJson(Map<String, dynamic> json) => ComboboxModel(
    description: json['description']?.toString(),
    displayMember: json['display_member']?.toString(),
    displaySequence: Parse.parseInt(json['display_sequence']),
    isActive: json['is_active'] as bool?,
    valueMember: json['value_member']?.toString(),
    valueMember1: json['value_member1']?.toString(),
    valueMember2: json['value_member2']?.toString(),
    valueMember3: json['value_member3']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'description': description,
    'display_member': displayMember,
    'display_sequence': displaySequence,
    'is_active': isActive,
    'value_member': valueMember,
    'value_member1': valueMember1,
    'value_member2': valueMember2,
    'value_member3': valueMember3,
  };

  String get label {
    final display = displayMember?.trim();
    if (display != null && display.isNotEmpty) return display;
    return valueMember?.trim() ?? '';
  }

  String get value => valueMember?.trim() ?? '';
}
