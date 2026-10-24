import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/dates/reporting_time_zone.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/failure_messages.dart';
import '../domain/scan_record.dart';
import '../domain/scan_status.dart';

/// One imported slip with its status and the actions that status allows.
///
/// The review screen (ROADMAP week 7) will open from `needsReview` scans.
class ScanTile extends StatelessWidget {
  const ScanTile({
    super.key,
    required this.scan,
    required this.onRetry,
    required this.onDiscard,
  });

  final ScanRecord scan;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final created = ReportingTimeZone.bangkok.wallClock(scan.createdAt);
    final failure = scan.failureCode;
    final canRetry =
        scan.status == ScanStatus.failed || scan.status == ScanStatus.queued;
    final canDiscard = scan.status.canTransitionTo(ScanStatus.discarded);

    return ListTile(
      leading: Icon(_icon(scan.status)),
      title: Text(_statusLabel(l10n, scan.status)),
      subtitle: Text(
        [
          _sourceLabel(l10n, scan.source),
          DateFormat.yMMMd(locale).add_Hm().format(created),
          if (failure != null) l10n.failureMessage(failure),
        ].join(' · '),
      ),
      isThreeLine: failure != null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canRetry)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.retry,
              onPressed: onRetry,
            ),
          if (canDiscard)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.discard,
              onPressed: onDiscard,
            ),
        ],
      ),
    );
  }

  static IconData _icon(ScanStatus status) => switch (status) {
    ScanStatus.queued => Icons.schedule,
    ScanStatus.processing => Icons.hourglass_top,
    ScanStatus.needsReview => Icons.rate_review_outlined,
    ScanStatus.confirmed => Icons.check_circle_outline,
    ScanStatus.duplicate => Icons.content_copy,
    ScanStatus.failed => Icons.error_outline,
    ScanStatus.discarded => Icons.delete_outline,
  };

  static String _statusLabel(AppLocalizations l10n, ScanStatus status) =>
      switch (status) {
        ScanStatus.queued => l10n.scanStatusQueued,
        ScanStatus.processing => l10n.scanStatusProcessing,
        ScanStatus.needsReview => l10n.scanStatusNeedsReview,
        ScanStatus.confirmed => l10n.scanStatusConfirmed,
        ScanStatus.duplicate => l10n.scanStatusDuplicate,
        ScanStatus.failed => l10n.scanStatusFailed,
        ScanStatus.discarded => l10n.scanStatusDiscarded,
      };

  static String _sourceLabel(AppLocalizations l10n, ImportSource source) =>
      switch (source) {
        ImportSource.camera => l10n.scanSourceCamera,
        ImportSource.gallery => l10n.scanSourceGallery,
        ImportSource.shareSheet => l10n.scanSourceShareSheet,
        ImportSource.discovery => l10n.scanSourceDiscovery,
      };
}
