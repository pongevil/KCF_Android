enum AiActionType {
  answerOnly,
  navigate,
  pendingCrud,
  openScanner,
  unknown;

  static AiActionType fromDecision(
    String? decision, {
    bool requiresConfirmation = false,
    String? action,
  }) {
    if (requiresConfirmation) return AiActionType.pendingCrud;

    final normalizedAction = action?.trim().toLowerCase();
    if (normalizedAction == 'navigate') return AiActionType.navigate;
    if (normalizedAction == 'scan' ||
        normalizedAction == 'scanner' ||
        normalizedAction == 'open_scanner') {
      return AiActionType.openScanner;
    }

    switch (decision?.toUpperCase().trim()) {
      case 'BYPASS_SQL':
      case 'RBAC_DENY':
      case 'ANSWER_ONLY':
      case 'ANSWER':
      case 'SELECT':
      case 'QUERY':
      case 'READ':
      case '':
      case null:
        return AiActionType.answerOnly;
      case 'NAVIGATE':
      case 'NAVIGATION':
        return AiActionType.navigate;
      case 'GENERATE_SQL':
      case 'INSERT':
      case 'UPDATE':
      case 'DELETE':
      case 'PENDING':
      case 'PENDING_CRUD':
      case 'PENDING_CRUD_CONFIRM':
      case 'CRUD_PENDING':
        return AiActionType.pendingCrud;
      case 'OPEN_SCANNER':
      case 'SCAN_BARCODE':
      case 'SCANNER':
        return AiActionType.openScanner;
      default:
        return AiActionType.unknown;
    }
  }
}
