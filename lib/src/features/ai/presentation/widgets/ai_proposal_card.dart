import 'package:bs_mobile/src/core/ai/models/ai_proposal.dart';
import 'package:bs_mobile/src/core/localization/locale_extension.dart';
import 'package:bs_mobile/src/core/theme/app_theme_extension.dart';
import 'package:bs_mobile/src/core/theme/theme_extensions.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

class AiProposalCard extends StatelessWidget {
  const AiProposalCard({
    super.key,
    required this.proposal,
    required this.onConfirm,
    required this.onReject,
    this.isBusy = false,
  });

  final AiProposal proposal;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final app = context.appTheme;
    final plan = proposal.businessPlan;
    final statusMeta = _statusMeta(context, proposal.status, app, cs);
    final showActions = proposal.canInteract;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: statusMeta.accent.withValues(alpha: 0.28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [statusMeta.accent.withValues(alpha: 0.14), cs.surface],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusMeta.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    statusMeta.icon,
                    size: 20,
                    color: statusMeta.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        context.tr(
                          'mobile.ai_proposal_title',
                          fallback: 'ร่างรายการ (AI Proposal)',
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        context.tr(
                          'mobile.ai_proposal_subtitle',
                          fallback: 'ตรวจสอบก่อนบันทึกข้อมูล',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(label: statusMeta.label, color: statusMeta.accent),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaTile(
                  icon: Icons.playlist_add_check_rounded,
                  label: context.tr(
                    'mobile.ai_proposal_activity',
                    fallback: 'กิจกรรม',
                  ),
                  value:
                      plan?.activity ?? prettyBusinessActivity(proposal.action),
                  accent: cs.primary,
                ),
                const SizedBox(height: 8),
                _MetaTile(
                  icon: Icons.dataset_rounded,
                  label: context.tr(
                    'mobile.ai_proposal_target',
                    fallback: 'ชุดข้อมูล',
                  ),
                  value: plan?.target ?? '-',
                  accent: app.info,
                ),
                const SizedBox(height: 12),
                _DetailPanel(
                  icon: Icons.summarize_outlined,
                  title: context.tr(
                    'mobile.ai_proposal_summary',
                    fallback: 'สรุปข้อมูล',
                  ),
                  value: plan?.dataSummary ?? '-',
                ),
                const SizedBox(height: 8),
                _DetailPanel(
                  icon: Icons.link_rounded,
                  title: context.tr(
                    'mobile.ai_proposal_reference',
                    fallback: 'รายการอ้างอิง',
                  ),
                  value: plan?.reference ?? '-',
                ),
                if (proposal.confirmMessage != null &&
                    proposal.confirmMessage!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FeedbackBanner(
                    message: proposal.confirmMessage!,
                    isSuccess: proposal.status == AiProposalStatus.confirmed,
                  ),
                ],
                if (showActions) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: _rejectLabel(context, proposal.status),
                          icon: Icons.close_rounded,
                          foreground: app.buttonWarning,
                          background: app.buttonWarning.withValues(alpha: 0.1),
                          borderColor: app.buttonWarning.withValues(
                            alpha: 0.35,
                          ),
                          onPressed: isBusy ? null : onReject,
                          isLoading:
                              proposal.status == AiProposalStatus.rejecting,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _ActionButton(
                          label: _confirmLabel(context, proposal.status),
                          icon: Icons.check_circle_outline_rounded,
                          foreground: app.buttonSuccessOn,
                          background: app.buttonSuccess,
                          borderColor: app.buttonSuccess,
                          onPressed: isBusy ? null : onConfirm,
                          isLoading:
                              proposal.status == AiProposalStatus.confirming,
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusVisual _statusMeta(
    BuildContext context,
    AiProposalStatus status,
    AppThemeExtension app,
    ColorScheme cs,
  ) {
    switch (status) {
      case AiProposalStatus.confirmed:
        return _StatusVisual(
          label: proposalStatusLabel(status),
          accent: app.buttonSuccess,
          icon: Icons.verified_rounded,
        );
      case AiProposalStatus.failed:
        return _StatusVisual(
          label: proposalStatusLabel(status),
          accent: app.buttonDanger,
          icon: Icons.error_outline_rounded,
        );
      case AiProposalStatus.rejected:
      case AiProposalStatus.rejecting:
        return _StatusVisual(
          label: proposalStatusLabel(status),
          accent: app.buttonWarning,
          icon: Icons.block_rounded,
        );
      case AiProposalStatus.confirming:
        return _StatusVisual(
          label: proposalStatusLabel(status),
          accent: cs.primary,
          icon: Icons.hourglass_top_rounded,
        );
      case AiProposalStatus.pending:
        return _StatusVisual(
          label: proposalStatusLabel(status),
          accent: app.buttonWarning,
          icon: Icons.pending_actions_rounded,
        );
    }
  }

  String _confirmLabel(BuildContext context, AiProposalStatus status) {
    switch (status) {
      case AiProposalStatus.confirmed:
        return context.tr(
          'mobile.ai_proposal_confirmed',
          fallback: 'ยืนยันแล้ว',
        );
      case AiProposalStatus.confirming:
        return context.tr(
          'mobile.ai_proposal_saving',
          fallback: 'กำลังบันทึก...',
        );
      default:
        return context.tr(
          'mobile.ai_proposal_confirm_save',
          fallback: 'ยืนยันและบันทึก',
        );
    }
  }

  String _rejectLabel(BuildContext context, AiProposalStatus status) {
    switch (status) {
      case AiProposalStatus.rejected:
        return context.tr(
          'mobile.ai_proposal_cancelled',
          fallback: 'ยกเลิกแล้ว',
        );
      case AiProposalStatus.rejecting:
        return context.tr(
          'mobile.ai_proposal_cancelling',
          fallback: 'กำลังยกเลิก...',
        );
      default:
        return context.tr('mobile.ai_proposal_cancel', fallback: 'ยกเลิก');
    }
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.label,
    required this.accent,
    required this.icon,
  });

  final String label;
  final Color accent;
  final IconData icon;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: AppText(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            AppText(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: AppText(
            value,
            style: TextStyle(fontSize: 12, height: 1.45, color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final app = context.appTheme;
    final color = isSuccess ? app.buttonSuccess : app.buttonDanger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppText(
              message,
              style: TextStyle(fontSize: 12, height: 1.35, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.borderColor,
    required this.onPressed,
    this.isLoading = false,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: filled ? background : borderColor),
            boxShadow: filled && onPressed != null
                ? [
                    BoxShadow(
                      color: background.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: foreground),
                      const SizedBox(width: 6),
                      Flexible(
                        child: AppText(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
