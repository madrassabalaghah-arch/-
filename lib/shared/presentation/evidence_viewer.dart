import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';

/// Opens an uploaded evidence file for whoever is allowed to see it.
///
/// The `evidence` bucket is private, so the file is reached through a
/// time-limited signed URL rather than a public link. Who may obtain one is
/// decided by the storage policy `evidence readable by owner mentor or admin`,
/// which calls `private.can_view_graduate()` — the graduate who uploaded it,
/// the mentor assigned to them, and an administrator. Asking for a URL to
/// someone else's evidence fails there, not here, so this helper cannot widen
/// access by mistake.
Future<void> openEvidence(
  BuildContext context,
  WidgetRef ref,
  EvidenceItem item,
) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  try {
    final String url = await ref
        .read(graduateRepositoryProvider)
        .signedEvidenceUrl(item.storagePath);

    final Uri? uri = Uri.tryParse(url);
    final bool opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.couldNotOpenEvidence)),
        );
    }
  } catch (error) {
    // A refusal from storage lands here too, so the reader is told the file
    // could not be opened rather than being left with a tap that did nothing.
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('${AppStrings.couldNotOpenEvidence} — $error')),
      );
  }
}
