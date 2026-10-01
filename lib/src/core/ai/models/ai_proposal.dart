import 'package:bs_mobile/src/core/ai/models/ai_table_data.dart';

enum AiProposalStatus {
  pending,
  confirming,
  confirmed,
  rejecting,
  rejected,
  failed;

  static AiProposalStatus fromApi(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'confirmed':
        return AiProposalStatus.confirmed;
      case 'confirming':
        return AiProposalStatus.confirming;
      case 'rejecting':
        return AiProposalStatus.rejecting;
      case 'failed':
        return AiProposalStatus.failed;
      case 'rejected':
        return AiProposalStatus.rejected;
      default:
        return AiProposalStatus.pending;
    }
  }

  bool get isTerminal =>
      this == confirmed || this == rejected || this == failed;
}

class AiBusinessPlan {
  const AiBusinessPlan({
    this.target,
    this.activity,
    this.dataSummary,
    this.reference,
  });

  final String? target;
  final String? activity;
  final String? dataSummary;
  final String? reference;

  bool get hasContent =>
      _hasText(target) ||
      _hasText(activity) ||
      _hasText(dataSummary) ||
      _hasText(reference);

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  factory AiBusinessPlan.fromDynamic(dynamic data) {
    final map = parseObjectOrEmpty(data);
    return AiBusinessPlan(
      target: _normalizeBusinessText(map['target'] ?? map['Target']),
      activity: _normalizeBusinessText(map['activity'] ?? map['Activity']),
      dataSummary: _normalizeBusinessText(
        map['data_summary'] ?? map['dataSummary'] ?? map['DataSummary'],
      ),
      reference: _normalizeBusinessText(map['reference'] ?? map['Reference']),
    );
  }
}

class AiProposal {
  const AiProposal({
    required this.action,
    this.table,
    this.fields = const {},
    this.where = const {},
    this.businessPlan,
    this.status = AiProposalStatus.pending,
    this.aiCrudAuditLogId,
    this.requestId,
    this.confirmMessage,
    this.confirmError,
  });

  final String action;
  final String? table;
  final Map<String, dynamic> fields;
  final Map<String, dynamic> where;
  final AiBusinessPlan? businessPlan;
  final AiProposalStatus status;
  final int? aiCrudAuditLogId;
  final String? requestId;
  final String? confirmMessage;
  final String? confirmError;

  bool get canInteract =>
      !status.isTerminal &&
      status != AiProposalStatus.confirming &&
      status != AiProposalStatus.rejecting;

  AiProposal copyWith({
    AiProposalStatus? status,
    String? confirmMessage,
    String? confirmError,
    bool clearConfirmMessage = false,
    bool clearConfirmError = false,
  }) {
    return AiProposal(
      action: action,
      table: table,
      fields: fields,
      where: where,
      businessPlan: businessPlan,
      status: status ?? this.status,
      aiCrudAuditLogId: aiCrudAuditLogId,
      requestId: requestId,
      confirmMessage: clearConfirmMessage
          ? null
          : (confirmMessage ?? this.confirmMessage),
      confirmError: clearConfirmError
          ? null
          : (confirmError ?? this.confirmError),
    );
  }

  Map<String, dynamic> toConfirmJson({
    required String process,
    required String userId,
    required String userName,
    required String fallbackRequestId,
  }) {
    return {
      'ai_crud_audit_log_id': aiCrudAuditLogId,
      'request_id': requestId ?? fallbackRequestId,
      'process': process,
      'user_id': userId,
      'user_name': userName,
      'action': action,
      'table': table,
      'fields': fields,
      'where': where,
    };
  }
}

bool isCrudProposalAction(String? action) {
  switch (action?.trim().toLowerCase()) {
    case 'insert':
    case 'update':
    case 'delete':
      return true;
    default:
      return false;
  }
}

String prettyBusinessActivity(String? action, {String lang = 'th'}) {
  final normalized = action?.trim().toLowerCase() ?? '';
  if (lang == 'th') {
    switch (normalized) {
      case 'insert':
        return 'เพิ่มรายการใหม่';
      case 'update':
        return 'ปรับปรุงข้อมูลรายการ';
      case 'delete':
        return 'ยกเลิกการใช้งานรายการ';
      default:
        return 'ดำเนินการกับรายการนี้';
    }
  }

  switch (normalized) {
    case 'insert':
      return 'Create a new record';
    case 'update':
      return 'Update the selected record';
    case 'delete':
      return 'Deactivate the selected record';
    default:
      return 'Process this record';
  }
}

String _normalizeBusinessText(dynamic value) {
  return (value?.toString() ?? '')
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

AiBusinessPlan? buildProposalBusinessPlan({
  required Map<String, dynamic>? businessPlan,
  required String? action,
  required Map<String, dynamic> fields,
  required Map<String, dynamic> where,
  required String responseText,
  String lang = 'th',
}) {
  final plan = businessPlan != null
      ? AiBusinessPlan.fromDynamic(businessPlan)
      : const AiBusinessPlan();

  final referenceCandidates = <String>[
    ...where.values.map(_referenceTextFromValue),
    ...fields.values.map(_referenceTextFromValue),
  ].where((value) => value.isNotEmpty).take(3).toList();

  final built = AiBusinessPlan(
    target: plan.target?.isNotEmpty == true
        ? plan.target
        : (lang == 'th' ? 'ข้อมูลรายการนี้' : 'This business record'),
    activity: plan.activity?.isNotEmpty == true
        ? plan.activity
        : prettyBusinessActivity(action, lang: lang),
    dataSummary: plan.dataSummary?.isNotEmpty == true
        ? plan.dataSummary
        : (_normalizeBusinessText(responseText).isNotEmpty
              ? _normalizeBusinessText(responseText)
              : (lang == 'th'
                    ? 'ระบบเตรียมดำเนินการตามรายการนี้'
                    : 'The system is ready to perform this action.')),
    reference: plan.reference?.isNotEmpty == true
        ? plan.reference
        : (referenceCandidates.isNotEmpty
              ? (lang == 'th'
                    ? 'อ้างอิงจาก ${referenceCandidates.join(', ')}'
                    : 'Based on ${referenceCandidates.join(', ')}')
              : (lang == 'th'
                    ? 'อ้างอิงจากรายการที่เลือก'
                    : 'Based on the selected record')),
  );

  return built.hasContent ? built : null;
}

AiProposal? buildProposalFromResponse({
  required Map<String, dynamic> payload,
  required String responseText,
  String lang = 'th',
}) {
  final aiDecision = (payload['ai_decision'] ?? payload['aiDecision'] ?? '')
      .toString()
      .trim();
  final requiresConfirmation = _parseBool(
    payload['requires_confirmation'] ?? payload['RequiresConfirmation'],
  );
  final action = (payload['action'] ?? payload['Action'] ?? '').toString();
  final table = (payload['table'] ?? payload['Table'])?.toString();
  final fields = parseObjectOrEmpty(payload['fields'] ?? payload['Fields']);
  final where = parseObjectOrEmpty(payload['where'] ?? payload['Where']);
  final businessPlan = buildProposalBusinessPlan(
    businessPlan: parseObjectOrEmpty(
      payload['business_plan'] ?? payload['BusinessPlan'],
    ),
    action: action,
    fields: fields,
    where: where,
    responseText: responseText,
    lang: lang,
  );
  final aiCrudAuditLogId = _readInt(
    payload['ai_crud_audit_log_id'] ?? payload['AiCrudAuditLogId'],
  );
  final requestId = (payload['request_id'] ?? payload['RequestId'])?.toString();
  final confirmStatus = AiProposalStatus.fromApi(
    (payload['confirm_status'] ?? payload['ConfirmStatus'])?.toString(),
  );

  final shouldRender =
      aiDecision.toUpperCase() == 'GENERATE_SQL' &&
      isCrudProposalAction(action);
  final hasProposal =
      shouldRender &&
      (requiresConfirmation ||
          (table != null && table.isNotEmpty) ||
          fields.isNotEmpty ||
          where.isNotEmpty ||
          businessPlan != null ||
          aiCrudAuditLogId != null);

  if (!hasProposal) return null;

  final status =
      confirmStatus == AiProposalStatus.pending && requiresConfirmation
      ? AiProposalStatus.pending
      : confirmStatus;

  return AiProposal(
    action: action,
    table: table,
    fields: fields,
    where: where,
    businessPlan: businessPlan,
    status: status,
    aiCrudAuditLogId: aiCrudAuditLogId,
    requestId: requestId,
  );
}

bool _parseBool(dynamic value) {
  return value == true || value == 1 || value == '1' || value == 'true';
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value != null) return int.tryParse(value.toString());
  return null;
}

String _referenceTextFromValue(dynamic value) {
  if (value is Map) return '';
  if (value is Iterable && value is! String) {
    return _normalizeBusinessText(
      value.map((item) => item.toString()).join(', '),
    );
  }
  return _normalizeBusinessText(value);
}

String proposalStatusLabel(AiProposalStatus status, {String lang = 'th'}) {
  switch (status) {
    case AiProposalStatus.confirmed:
      return lang == 'th' ? 'ยืนยันแล้ว' : 'Confirmed';
    case AiProposalStatus.confirming:
      return lang == 'th' ? 'กำลังบันทึก' : 'Saving';
    case AiProposalStatus.rejecting:
      return lang == 'th' ? 'กำลังยกเลิก' : 'Cancelling';
    case AiProposalStatus.failed:
      return lang == 'th' ? 'ล้มเหลว' : 'Failed';
    case AiProposalStatus.rejected:
      return lang == 'th' ? 'ถูกปฏิเสธ' : 'Rejected';
    case AiProposalStatus.pending:
      return lang == 'th' ? 'รอยืนยัน' : 'Pending';
  }
}
