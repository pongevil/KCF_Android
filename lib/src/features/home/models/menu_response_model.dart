// To parse this JSON data, do
//
//     final menuResponse = menuResponseFromJson(jsonString);

import 'dart:convert';

import 'package:bs_mobile/index.dart';

MenuResponse menuResponseFromJson(String str) =>
    MenuResponse.fromJson(json.decode(str));

String menuResponseToJson(MenuResponse data) => json.encode(data.toJson());

class MenuResponse {
  List<MenuData>? data;
  String? messageCode;
  String? messageText;

  MenuResponse({this.data, this.messageCode, this.messageText});

  factory MenuResponse.fromJson(Map<String, dynamic> json) => MenuResponse(
    data: json["data"] == null
        ? null
        : List<MenuData>.from(json["data"].map((x) => MenuData.fromJson(x))),
    messageCode: Parse.parseString(json["message_code"]),
    messageText: Parse.parseString(json["message_text"]),
  );

  Map<String, dynamic> toJson() => {
    "data": data == null
        ? null
        : List<dynamic>.from(data!.map((x) => x.toJson())),
    "message_code": messageCode,
    "message_text": messageText,
  };
}

class MenuData {
  int? userGroupId;
  bool? isAddView;
  bool? isEditView;
  bool? isDeleteView;
  bool? isView;
  int? menuId;
  int? parentMenuId;
  String? menuName;
  String? menuGroup;
  String? menuPath;
  int? menuSequence;
  int? menuGroupSequence;
  int? menuFavoriteId;

  MenuData({
    this.userGroupId,
    this.isAddView,
    this.isEditView,
    this.isDeleteView,
    this.isView,
    this.menuId,
    this.parentMenuId,
    this.menuName,
    this.menuGroup,
    this.menuPath,
    this.menuSequence,
    this.menuGroupSequence,
    this.menuFavoriteId,
  });

  factory MenuData.fromJson(Map<String, dynamic> json) => MenuData(
    userGroupId: Parse.parseInt(json["user_group_id"]),
    isAddView: Parse.parseBool(json["is_add_view"]),
    isEditView: Parse.parseBool(json["is_edit_view"]),
    isDeleteView: Parse.parseBool(json["is_delete_view"]),
    isView: Parse.parseBool(json["is_view"]),
    menuId: Parse.parseInt(json["menu_id"]),
    parentMenuId: Parse.parseInt(json["parent_menu_id"]),
    menuName: Parse.parseString(json["menu_name"]),
    menuGroup: Parse.parseString(json["menu_group"]),
    menuPath: Parse.parseString(json["menu_path"]),
    menuSequence: Parse.parseInt(json["menu_sequence"]),
    menuGroupSequence: Parse.parseInt(json["menu_group_sequence"]),
    menuFavoriteId: Parse.parseInt(json["menu_favorite_id"]),
  );

  Map<String, dynamic> toJson() => {
    "user_group_id": userGroupId,
    "is_add_view": isAddView,
    "is_edit_view": isEditView,
    "is_delete_view": isDeleteView,
    "is_view": isView,
    "menu_id": menuId,
    "parent_menu_id": parentMenuId,
    "menu_name": menuName,
    "menu_group": menuGroup,
    "menu_path": menuPath,
    "menu_sequence": menuSequence,
    "menu_group_sequence": menuGroupSequence,
    "menu_favorite_id": menuFavoriteId,
  };
}
