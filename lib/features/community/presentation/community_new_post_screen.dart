import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/providers/data_providers.dart';
import '../../../shared/widgets/widgets.dart';

/// نئی پوسٹ: a مربی or منتظم writing straight to the کمیونٹی بورڈ.
///
/// A فاضل / فاضلہ never reaches this screen, and would be refused by the
/// database if they did: the policy allows the insert only for an account
/// holding the mentor or administrator role, writing as itself.
class CommunityNewPostScreen extends ConsumerStatefulWidget {
  const CommunityNewPostScreen({super.key});

  @override
  ConsumerState<CommunityNewPostScreen> createState() =>
      _CommunityNewPostScreenState();
}

class _CommunityNewPostScreenState
    extends ConsumerState<CommunityNewPostScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(communityRepositoryProvider).createPost(
            title: _title.text,
            body: _body.text,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.postPublished)));
      Navigator.of(context).maybePop();
    } catch (error) {
      setState(() {
        _busy = false;
        _error = '${AppStrings.somethingWentWrong} — $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppScaffold(
      title: AppStrings.newPost,
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.bottomSafeArea,
          ),
          children: <Widget>[
            if (_error != null) ...<Widget>[
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.error),
                ),
              ),
              AppSpacing.gapLg,
            ],
            Text(AppStrings.communityBoardSubtitle,
                style: theme.textTheme.labelSmall),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.postTitle,
              controller: _title,
              isRequired: true,
              enabled: !_busy,
              prefixIcon: Icons.title_outlined,
              validator: AppFormField.requiredValidator,
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.postBody,
              controller: _body,
              maxLines: 6,
              isRequired: true,
              enabled: !_busy,
              validator: AppFormField.requiredValidator,
            ),
            AppSpacing.gapXl,
            PrimaryButton(
              label: AppStrings.newPost,
              icon: Icons.campaign_outlined,
              isLoading: _busy,
              onPressed: _busy ? null : _publish,
            ),
            AppSpacing.gapMd,
            SecondaryButton(
              label: AppStrings.cancel,
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
