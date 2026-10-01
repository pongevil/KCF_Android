import 'package:bs_mobile/src/core/ai/ai_config.dart';
import 'package:bs_mobile/src/core/ai/models/ai_chat_message.dart';
import 'package:bs_mobile/src/core/ai/models/ai_chat_request.dart';
import 'package:bs_mobile/src/core/ai/models/ai_chat_response.dart';
import 'package:bs_mobile/src/core/ai/models/ai_page_context.dart';
import 'package:bs_mobile/src/core/ai/models/ai_proposal.dart';
import 'package:bs_mobile/src/core/ai/models/ai_suggestions_response.dart';
import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';

class AiChatRepository {
  AiChatRepository(this._client);

  final ApiClient _client;

  Future<String> _resolveLang() async {
    final lang = await AppStorage.getLocaleId();
    return lang.isEmpty ? 'th' : lang;
  }

  Future<AiChatResponse> sendMessage({
    required String process,
    required String userMessage,
    required List<AiChatMessage> conversationHistory,
    AiPageContext? pageContext,
  }) async {
    final userId = await AppStorage.getUserId();
    final userName = await AppStorage.getUsername();
    final lang = await _resolveLang();

    final augmentedHistory = _augmentHistory(conversationHistory, pageContext);
    final augmentedMessage =
        pageContext?.augmentUserMessage(userMessage) ?? userMessage;

    final request = AiChatRequest(
      process: process,
      userMessage: augmentedMessage,
      conversationHistory: augmentedHistory,
      userId: userId,
      userName: userName,
    );

    final response = await _client.post(
      AiConfig.chatCompletionsPath,
      data: request.toJson(),
      timeoutSec: AiConfig.receiveTimeoutSec,
      showAlert: false,
    );

    return AiChatResponse.fromDynamic(response.data, lang: lang);
  }

  Future<AiActionResult> confirmProposal({
    required String process,
    required AiProposal proposal,
    required String fallbackRequestId,
  }) async {
    final userId = await AppStorage.getUserId() ?? 'anonymous';
    final userName = await AppStorage.getUsername() ?? '';

    final response = await _client.post(
      AiConfig.confirmPath,
      data: proposal.toConfirmJson(
        process: process,
        userId: userId,
        userName: userName,
        fallbackRequestId: fallbackRequestId,
      ),
      timeoutSec: AiConfig.receiveTimeoutSec,
      showAlert: false,
    );

    return AiActionResult.fromDynamic(
      response.data,
      httpOk: response.statusCode == 200,
    );
  }

  Future<AiActionResult> rejectProposal({
    required String process,
    required AiProposal proposal,
    required String fallbackRequestId,
  }) async {
    final userId = await AppStorage.getUserId() ?? 'anonymous';
    final userName = await AppStorage.getUsername() ?? '';

    final response = await _client.post(
      AiConfig.rejectPath,
      data: proposal.toConfirmJson(
        process: process,
        userId: userId,
        userName: userName,
        fallbackRequestId: fallbackRequestId,
      ),
      timeoutSec: AiConfig.receiveTimeoutSec,
      showAlert: false,
    );

    return AiActionResult.fromDynamic(
      response.data,
      httpOk: response.statusCode == 200,
    );
  }

  Future<List<String>> fetchSuggestions({
    required String process,
    int count = AiConfig.defaultSuggestionCount,
    int? systemPromptId,
  }) async {
    final userId = await AppStorage.getUserId();
    final userName = await AppStorage.getUsername();
    final lang = await _resolveLang();

    final body = <String, dynamic>{
      'process': process,
      'lang': lang,
      'user_id': userId ?? '',
      'user_name': userName ?? '',
      'count': count,
      if (systemPromptId != null) 'system_prompt_id': systemPromptId,
    };

    final response = await _client.post(
      AiConfig.suggestionsPath,
      data: body,
      timeoutSec: AiConfig.receiveTimeoutSec,
      showAlert: false,
    );

    final parsed = AiSuggestionsResponse.fromDynamic(response.data);
    if (!parsed.success) return const [];

    return parsed.suggestions;
  }

  List<AiChatMessage> _augmentHistory(
    List<AiChatMessage> history,
    AiPageContext? pageContext,
  ) {
    if (pageContext == null || !pageContext.hasCondition) return history;

    return history.map((message) {
      if (message.role != AiChatRole.user) return message;

      return AiChatMessage(
        id: message.id,
        role: message.role,
        content: pageContext.augmentUserMessage(message.content),
        createdAt: message.createdAt,
        dataRows: message.dataRows,
        reportData: message.reportData,
        proposal: message.proposal,
      );
    }).toList();
  }
}
