import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/presentation/evidence_viewer.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Evidence the graduate has attached, with real uploads to Supabase Storage.
class GraduateEvidenceScreen extends ConsumerStatefulWidget {
  const GraduateEvidenceScreen({super.key});

  @override
  ConsumerState<GraduateEvidenceScreen> createState() =>
      _GraduateEvidenceScreenState();
}

class _GraduateEvidenceScreenState
    extends ConsumerState<GraduateEvidenceScreen> {
  bool _busy = false;

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Classifies a file for the `evidence_kind` enum from its extension.
  static String _kindOf(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return 'image';
      case 'mp4':
      case 'mov':
        return 'video';
      default:
        return 'document';
    }
  }

  static String? _mimeOf(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      default:
        return null;
    }
  }

  Future<void> _pickAndUpload() async {
    setState(() => _busy = true);
    try {
      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const <String>[
          'png', 'jpg', 'jpeg', 'webp', 'pdf', 'mp4', 'mov',
        ],
      );

      if (file == null) {
        return;
      }

      // The bucket rejects anything larger, but checking first is friendlier
      // than waiting for the upload to be refused.
      final int size = await file.length();
      if (size > 50 * 1024 * 1024) {
        _toast(AppStrings.validationFileSize);
        return;
      }

      // readAsBytes works on every platform, including web, where the file
      // has no path on disk.
      final Uint8List bytes = await file.readAsBytes();

      _toast(AppStrings.uploading);
      await ref.read(graduateRepositoryProvider).uploadEvidence(
            fileName: file.name,
            bytes: bytes,
            kind: _kindOf(file.extension),
            mimeType: _mimeOf(file.extension),
          );
      _toast(AppStrings.uploadSuccess);
    } catch (error) {
      _toast('${AppStrings.uploadFailed} — $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete(EvidenceItem item) async {
    try {
      await ref.read(graduateRepositoryProvider).deleteEvidence(item);
      _toast(AppStrings.evidenceDeleted);
    } catch (error) {
      _toast('${AppStrings.somethingWentWrong} — $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SearchableListScreen<EvidenceItem>(
      title: AppStrings.evidence,
      items: ref.watch(graduateEvidenceProvider),
      searchText: (EvidenceItem item) => '${item.title} ${item.typeLabel}',
      emptyIcon: Icons.folder_open_outlined,
      emptyTitle: AppStrings.noEvidenceYet,
      actions: <Widget>[
        IconButton(
          tooltip: AppStrings.uploadEvidence,
          icon: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.white,
                  ),
                )
              : const Icon(Icons.upload_file_outlined),
          onPressed: _busy ? null : _pickAndUpload,
        ),
      ],
      itemBuilder: (BuildContext context, EvidenceItem item) => AppListTile(
        title: item.title,
        subtitle: '${item.typeLabel} • ${item.sizeLabel}',
        detail: item.dateLabel,
        icon: item.icon,
        status: item.status,
        accentColor: AppColors.tealGreen,
        onTap: () => openEvidence(context, ref, item),
        trailing: IconButton(
          tooltip: AppStrings.delete,
          icon: const Icon(Icons.delete_outline, color: AppColors.gray),
          onPressed: _busy ? null : () => _delete(item),
        ),
      ),
    );
  }
}
