import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../l10n/app_localizations.dart';
import 'format.dart';
import 'theme/app_theme.dart';

export '../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeCode => Localizations.localeOf(this).languageCode;
}

/// Turns any error into a sentence for the user, never a stack trace.
String errorMessage(BuildContext context, Object error, {String? serverUrl}) {
  final l = context.l10n;
  if (error is! ApiException) return l.errorGeneric;
  switch (error.code) {
    case 'network_error':
      return l.errorNetwork(serverUrl ?? '');
    case 'not_found':
      return l.errorNotFound;
    case 'validation_failed':
      return l.errorValidation;
    case 'deadline_in_past':
      return l.errorDeadlinePast;
    case 'dependency_cycle':
      return l.errorDependencyCycle;
    case 'plan_exists':
      return l.errorPlanExists;
    case 'no_plan':
      return l.errorNoPlan;
    case 'suggestion_already_decided':
      return l.errorSuggestionDecided;
    case 'unsupported_file_type':
      return l.errorUnsupportedFile;
    case 'file_too_large':
      return l.errorFileTooLarge;
    case 'too_many_pages':
      return l.errorTooManyPages;
    case 'duplicate_document':
      return l.errorDuplicate;
    case 'unreadable_file':
    case 'encrypted_file':
      return l.errorUnreadable;
    case 'no_text_found':
      return l.errorNoText;
    case 'invalid_capacity':
      return l.errorInvalidCapacity;
    case 'empty_file':
      return l.errorEmptyFile;
    case 'ai_quota_exhausted':
      final resets = error.detail?['resets_at'] as String?;
      return l.errorQuota(resets == null ? '' : formatDate(context, DateTime.parse(resets)));
    case 'unauthenticated':
      return l.errorUnauthenticated;
    default:
      return l.errorGeneric;
  }
}

/// Document processing failures come back as codes on the document itself.
String documentErrorMessage(BuildContext context, String? code) => errorMessage(context, ApiException(code ?? 'unknown'));

/// Why the non-AI version was used, or null when AI worked.
String? aiFallbackReason(AppLocalizations l, String? code) {
  switch (code) {
    case null:
      return null;
    case 'ai_unavailable':
      return l.aiErrorUnavailable;
    case 'ai_quota_exhausted':
      return l.aiErrorQuota;
    case 'ai_invalid_plan':
      return l.aiErrorInvalidPlan;
    default:
      return l.aiErrorFailed;
  }
}

String healthLabel(AppLocalizations l, String? status) => switch (status) {
  'on_track' => l.healthOnTrack,
  'at_risk' => l.healthAtRisk,
  'off_track' => l.healthOffTrack,
  _ => l.healthNoPlan,
};

IconData healthIcon(String? status) => switch (status) {
  'on_track' => Icons.check_circle_outline,
  'at_risk' => Icons.error_outline,
  'off_track' => Icons.report_gmailerrorred_outlined,
  _ => Icons.radio_button_unchecked,
};

/// Foreground and background for a health status; always shown with icon and text too.
(Color, Color) healthColors(BuildContext context, String? status) {
  final s = context.statusColors;
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    'on_track' => (s.onSuccessContainer, s.successContainer),
    'at_risk' => (s.onWarningContainer, s.warningContainer),
    'off_track' => (scheme.onErrorContainer, scheme.errorContainer),
    _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHigh),
  };
}

String taskStatusLabel(AppLocalizations l, String status) => switch (status) {
  'in_progress' => l.statusInProgress,
  'done' => l.statusDone,
  _ => l.statusTodo,
};

String documentKindLabel(AppLocalizations l, String kind) => switch (kind) {
  'proposal' => l.docKindProposal,
  'instruction' => l.docKindInstruction,
  'journal' => l.docKindJournal,
  'supervision' => l.docKindSupervision,
  'draft' => l.docKindDraft,
  _ => l.docKindOther,
};

String suggestionKindLabel(AppLocalizations l, String kind) => switch (kind) {
  'plan' => l.suggestionKindPlan,
  'replan' => l.suggestionKindReplan,
  'brief_update' => l.suggestionKindBriefUpdate,
  _ => l.suggestionKindTaskChange,
};

String feasibilityLabel(AppLocalizations l, String? feasibility, double shortfallHours) => switch (feasibility) {
  'tight' => l.feasibilityTight,
  // Rounded up to a tenth: "short by 0 hours" would contradict the verdict.
  'infeasible' => l.feasibilityInfeasible(formatHours((shortfallHours * 10).ceilToDouble() / 10)),
  _ => l.feasibilityFeasible,
};

String healthReason(AppLocalizations l, String reason, int criticalLateDays) => switch (reason) {
  'infeasible' => l.healthReasonInfeasible,
  'critical_late_major' || 'critical_late_minor' => l.healthReasonCriticalLate(criticalLateDays),
  'spi_low' => l.healthReasonSpiLow,
  'spi_moderate' => l.healthReasonSpiModerate,
  _ => l.healthAllGood,
};
