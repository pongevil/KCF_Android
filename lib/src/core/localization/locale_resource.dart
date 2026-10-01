class LocaleResource {
  final int? resourceId;
  final int? appId;
  final String? platform;
  final String resourceGroup;
  final String resourceName;
  final String? resourceEn;
  final String? resourceTh;
  final String? resourceOther;
  final String? descriptionEn;
  final String? descriptionTh;
  final String? descriptionOther;
  final bool isActive;
  final String? microServiceName;
  final String? rowversion;
  final String? createBy;
  final String? createDate;

  const LocaleResource({
    this.resourceId,
    this.appId,
    this.platform,
    required this.resourceGroup,
    required this.resourceName,
    this.resourceEn,
    this.resourceTh,
    this.resourceOther,
    this.descriptionEn,
    this.descriptionTh,
    this.descriptionOther,
    this.isActive = true,
    this.microServiceName,
    this.rowversion,
    this.createBy,
    this.createDate,
  });

  String get lookupKey => '${resourceGroup.trim()}.${resourceName.trim()}';

  factory LocaleResource.fromJson(Map<String, dynamic> json) {
    final isActiveRaw = json['is_active'];
    final isActive =
        isActiveRaw == 1 ||
        isActiveRaw == true ||
        isActiveRaw == '1' ||
        isActiveRaw == null;

    return LocaleResource(
      resourceId: _asInt(json['resource_id']),
      appId: _asInt(json['app_id']),
      platform: json['platform']?.toString(),
      resourceGroup: json['resource_group']?.toString() ?? '',
      resourceName: json['resource_name']?.toString() ?? '',
      resourceEn: _nullableString(json['resource_en']),
      resourceTh: _nullableString(json['resource_th']),
      resourceOther: _nullableString(json['resource_other']),
      descriptionEn: _nullableString(json['description_en']),
      descriptionTh: _nullableString(json['description_th']),
      descriptionOther:
          _nullableString(json['descrption_other']) ??
          _nullableString(json['description_other']),
      isActive: isActive,
      microServiceName: json['micro_service_name']?.toString(),
      rowversion: json['rowversion']?.toString(),
      createBy: _nullableString(json['create_by']),
      createDate: _nullableString(json['create_date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'resource_id': resourceId,
    'app_id': appId,
    'platform': platform,
    'resource_group': resourceGroup,
    'resource_name': resourceName,
    'resource_en': resourceEn,
    'resource_th': resourceTh,
    'resource_other': resourceOther,
    'description_en': descriptionEn,
    'description_th': descriptionTh,
    'description_other': descriptionOther,
    'is_active': isActive ? 1 : 0,
    'micro_service_name': microServiceName,
    'rowversion': rowversion,
    'create_by': createBy,
    'create_date': createDate,
  };

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
