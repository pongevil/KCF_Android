/// AI chat endpoint configuration (uses gateway base URL from [AppStorage]).
abstract final class AiConfig {
  static const chatCompletionsPath = 'ai/chat';
  static const confirmPath = 'ai/confirm';
  static const rejectPath = 'ai/reject';
  static const suggestionsPath = 'ai/suggestions';

  static const defaultSuggestionCount = 4;

  /// AI responses can be slow — longer than default API calls.
  static const receiveTimeoutSec = 90;

  static const defaultMobileHomeProcess = '/master/warehouse';
}
