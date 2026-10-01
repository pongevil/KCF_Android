import 'package:bs_mobile/src/core/localization/locale_resource.dart';

class LocaleMapper {
  LocaleMapper._();

  static const mobilePlatform = 'MOBILE';
  static const webPlatform = 'WEB';

  /// Builds lookup keys as `{resource_group}.{resource_name}`.
  static Map<String, String> toMessages(
    List<LocaleResource> resources,
    String localeId, {
    String platform = mobilePlatform,
  }) {
    final normalizedLocale = localeId.toLowerCase();
    final acceptedPlatforms = {platform.toUpperCase(), webPlatform};

    final byKey = <String, LocaleResource>{};

    for (final resource in resources) {
      if (!resource.isActive) continue;
      if (resource.resourceGroup.isEmpty || resource.resourceName.isEmpty) {
        continue;
      }

      final resourcePlatform = resource.platform?.toUpperCase();
      if (resourcePlatform != null &&
          !acceptedPlatforms.contains(resourcePlatform)) {
        continue;
      }

      final key = '${resource.resourceGroup}.${resource.resourceName}';
      final existing = byKey[key];

      if (existing == null) {
        byKey[key] = resource;
        continue;
      }

      final existingPlatform = existing.platform?.toUpperCase();
      if (existingPlatform != platform.toUpperCase() &&
          resourcePlatform == platform.toUpperCase()) {
        byKey[key] = resource;
      }
    }

    final messages = <String, String>{};
    byKey.forEach((key, resource) {
      final text = _resolveText(resource, normalizedLocale);
      if (text != null) {
        messages[key] = text;
      }

      final description = _resolveDescription(resource, normalizedLocale);
      if (description != null) {
        messages['$key.description'] = description;
      }
    });

    return messages;
  }

  static String? _resolveText(LocaleResource resource, String localeId) {
    switch (localeId) {
      case 'th':
        return resource.resourceTh ??
            resource.resourceEn ??
            resource.resourceOther;
      case 'en':
        return resource.resourceEn ??
            resource.resourceTh ??
            resource.resourceOther;
      default:
        return resource.resourceOther ??
            resource.resourceEn ??
            resource.resourceTh;
    }
  }

  static String? _resolveDescription(LocaleResource resource, String localeId) {
    switch (localeId) {
      case 'th':
        return resource.descriptionTh ??
            resource.descriptionEn ??
            resource.descriptionOther;
      case 'en':
        return resource.descriptionEn ??
            resource.descriptionTh ??
            resource.descriptionOther;
      default:
        return resource.descriptionOther ??
            resource.descriptionEn ??
            resource.descriptionTh;
    }
  }
}
