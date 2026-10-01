import 'package:bs_mobile/src/core/ai/ai_action.dart';
import 'package:bs_mobile/src/core/ai/models/ai_proposal.dart';

class AiActionResult {
  const AiActionResult({required this.success, this.message});

  final bool success;
  final String? message;

  factory AiActionResult.fromDynamic(dynamic data, {required bool httpOk}) {
    if (data is! Map) {
      return AiActionResult(success: httpOk);
    }

    final map = Map<String, dynamic>.from(data);
    final success = _parseBool(map['success'] ?? map['Success']) ?? httpOk;
    final message = (map['message'] ?? map['Message'])?.toString();

    return AiActionResult(success: success, message: message);
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value == 1 || value == '1' || value == 'true') return true;
    if (value == 0 || value == '0' || value == 'false') return false;
    return null;
  }
}

class AiChatResponse {
  const AiChatResponse({
    required this.content,
    this.aiDecision,
    this.generatedSql,
    this.isSuccess = true,
    this.errorMessage,
    this.modelName,
    this.requiresConfirmation = false,
    this.action,
    this.table,
    this.fields = const {},
    this.where = const {},
    this.businessPlan,
    this.proposal,
    this.aiCrudAuditLogId,
    this.requestId,
    this.tokens,
    this.processingTimeMs,
    this.dataRows = const [],
    this.reportData,
    this.raw = const {},
  });

  final String content;
  final String? aiDecision;
  final String? generatedSql;
  final bool isSuccess;
  final String? errorMessage;
  final String? modelName;
  final bool requiresConfirmation;
  final String? action;
  final String? table;
  final Map<String, dynamic> fields;
  final Map<String, dynamic> where;
  final AiBusinessPlan? businessPlan;
  final AiProposal? proposal;
  final int? aiCrudAuditLogId;
  final String? requestId;
  final AiTokenUsage? tokens;
  final int? processingTimeMs;
  final List<Map<String, dynamic>> dataRows;
  final Map<String, dynamic>? reportData;
  final Map<String, dynamic> raw;

  bool get hasProposal => proposal != null;

  AiActionType get actionType => AiActionType.fromDecision(
    aiDecision,
    requiresConfirmation: requiresConfirmation,
    action: action,
  );

  bool get needsExecutorAction =>
      !hasProposal &&
      (actionType == AiActionType.navigate ||
          actionType == AiActionType.openScanner);

  factory AiChatResponse.fromDynamic(dynamic data, {String lang = 'th'}) {
    if (data is! Map) {
      return const AiChatResponse(
        content: '',
        isSuccess: false,
        errorMessage: 'Invalid AI response',
      );
    }

    final map = Map<String, dynamic>.from(data);
    final payload = _unwrapPayload(map);
    final content = _readText(payload, [
      'ai_response',
      'aiResponse',
      'content',
      'message',
      'message_text',
      'messageText',
    ]);

    final openAiContent = _readOpenAiContent(payload);
    final resolvedContent = content.isNotEmpty ? content : openAiContent;

    final isSuccess = _readBool(payload, [
      'success',
      'is_success',
      'isSuccess',
    ]);
    final errorMessage = _readText(payload, [
      'error_message',
      'errorMessage',
      'error',
    ]);

    final success =
        isSuccess ?? (resolvedContent.isNotEmpty && errorMessage.isEmpty);

    final requiresConfirmation =
        _readBool(payload, ['requires_confirmation', 'requiresConfirmation']) ??
        false;

    final fields = _readObject(payload['fields'] ?? payload['Fields']);
    final where = _readObject(payload['where'] ?? payload['Where']);
    final businessPlanRaw = payload['business_plan'] ?? payload['BusinessPlan'];
    final businessPlan = businessPlanRaw != null
        ? AiBusinessPlan.fromDynamic(businessPlanRaw)
        : null;
    final proposal = buildProposalFromResponse(
      payload: payload,
      responseText: resolvedContent,
      lang: lang,
    );

    return AiChatResponse(
      content: resolvedContent,
      aiDecision: _readText(payload, ['ai_decision', 'aiDecision']),
      generatedSql: _readNullableText(payload, [
        'generated_sql',
        'generatedSql',
      ]),
      isSuccess: success,
      errorMessage: success
          ? null
          : (errorMessage.isEmpty ? null : errorMessage),
      modelName: _readText(payload, [
        'model_used',
        'model_name',
        'modelName',
        'model',
      ]),
      requiresConfirmation: requiresConfirmation,
      action: _readNullableText(payload, ['action', 'Action']),
      table: _readNullableText(payload, ['table', 'Table']),
      fields: fields,
      where: where,
      businessPlan: businessPlan,
      proposal: proposal,
      aiCrudAuditLogId: _readInt(payload, [
        'ai_crud_audit_log_id',
        'aiCrudAuditLogId',
      ]),
      requestId: _readNullableText(payload, ['request_id', 'RequestId']),
      tokens: AiTokenUsage.fromDynamic(payload['tokens']),
      processingTimeMs: _readInt(payload, [
        'processing_time_ms',
        'processingTimeMs',
      ]),
      dataRows: _readDataRows(payload['data_rows'] ?? payload['dataRows']),
      reportData: _readObjectOrNull(
        payload['report_data'] ?? payload['reportData'],
      ),
      raw: payload,
    );
  }

  static Map<String, dynamic> _unwrapPayload(Map<String, dynamic> map) {
    final data = map['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return map;
  }

  static Map<String, dynamic> _readObject(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static Map<String, dynamic>? _readObjectOrNull(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _readText(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static String? _readNullableText(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final text = _readText(map, keys);
    return text.isEmpty ? null : text;
  }

  static bool? _readBool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value == 1 || value == '1' || value == 'true') return true;
      if (value == 0 || value == '0' || value == 'false') return false;
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value != null) return int.tryParse(value.toString());
    }
    return null;
  }

  static List<Map<String, dynamic>> _readDataRows(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  static String _readOpenAiContent(Map<String, dynamic> map) {
    final choices = map['choices'];
    if (choices is! List || choices.isEmpty) return '';

    final first = choices.first;
    if (first is! Map) return '';

    final message = first['message'];
    if (message is Map) {
      final content = message['content'];
      if (content != null) return content.toString();
    }

    final text = first['text'];
    if (text != null) return text.toString();

    return '';
  }
}

class AiTokenUsage {
  const AiTokenUsage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });

  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  factory AiTokenUsage.fromDynamic(dynamic data) {
    if (data is! Map) return const AiTokenUsage();

    final map = Map<String, dynamic>.from(data);
    return AiTokenUsage(
      promptTokens: _readInt(map, ['prompt_tokens', 'promptTokens']),
      completionTokens: _readInt(map, [
        'completion_tokens',
        'completionTokens',
      ]),
      totalTokens: _readInt(map, ['total_tokens', 'totalTokens']),
    );
  }

  static int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value != null) return int.tryParse(value.toString());
    }
    return null;
  }
}
