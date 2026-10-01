import 'package:bs_mobile/src/core/localization/locale_strings_response.dart';
import 'package:flutter/widgets.dart';

/// In-memory store for API-driven locale strings.
/// All pages read from this singleton after login / app start.
class LocaleService extends ChangeNotifier {
  LocaleService._();

  static final LocaleService instance = LocaleService._();

  Map<String, String> _messages = {};
  Map<String, String> _fallback = {};

  bool get isLoaded => _messages.isNotEmpty;

  void setMessages(Map<String, String> messages) {
    _messages = Map<String, String>.from(messages);
    notifyListeners();
  }

  void setFallback(Map<String, String> fallback) {
    _fallback = Map<String, String>.from(fallback);
    notifyListeners();
  }

  void apply(LocaleStringsResponse response) {
    setMessages(response.messages);
  }

  void clear() {
    _messages = {};
    notifyListeners();
  }

  String tr(String key, {String? fallback, Map<String, String>? params}) {
    var value = _messages[key] ?? _fallback[key] ?? fallback ?? key;

    if (params != null) {
      params.forEach((name, replacement) {
        value = value.replaceAll('{$name}', replacement);
      });
    }

    return value;
  }
}

/// Makes API-driven translations reactive for widgets that call `context.tr`.
class LocaleServiceScope extends InheritedNotifier<LocaleService> {
  const LocaleServiceScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static LocaleService of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<LocaleServiceScope>()
            ?.notifier ??
        LocaleService.instance;
  }
}
