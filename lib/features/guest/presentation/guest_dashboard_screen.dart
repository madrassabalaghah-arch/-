import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/urdu_numbers.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/data_providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/sign_out_action.dart';

/// What the institution has to show the public: how many فاضل و فاضلہ it has
/// sent out, and what they have done since.
///
/// Every figure is a total. Nothing here names a person, quotes a کارگزاری
/// or opens a file, and there is no control on this screen that writes
/// anything — which is the whole of what a مہمان is allowed to do. The
/// database enforces the same thing independently.
///
/// It is also reachable without signing in, because this is the part of the
/// app that is meant to be shown to anybody.
class GuestDashboardScreen extends ConsumerWidget {
  const GuestDashboardScreen({super.key});

  /// The MADRASSA.PK تعارف page, opened in the device's own browser.
  static const String websiteUrl =
      'https://madrassa.pk/%d8%aa%d8%b9%d8%a7%d8%b1%d9%81/';

  static Future<void> _openWebsite(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Uri uri = Uri.parse(websiteUrl);
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.couldNotOpenLink)),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<PublicStatistics> statistics =
        ref.watch(publicStatisticsProvider);
    final AsyncValue<List<PublicActivityCount>> activity =
        ref.watch(publicActivityProvider);
    final bool signedIn = ref.watch(appSessionProvider).value != null;

    Future<void> refresh() async {
      ref.invalidate(publicStatisticsProvider);
      ref.invalidate(publicActivityProvider);
      await Future.wait<Object?>(<Future<Object?>>[
        ref.read(publicStatisticsProvider.future),
        ref.read(publicActivityProvider.future),
      ]);
    }

    return AppScaffold(
      showAppBar: false,
      padBody: false,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.bottomSafeArea,
          ),
          children: <Widget>[
            _Header(signedIn: signedIn),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SectionHeader(title: AppStrings.guestIntroTitle),
                  Text(AppStrings.guestIntro, style: theme.textTheme.bodyMedium),
                  AppSpacing.gapXl,
                  const SectionHeader(title: AppStrings.guestStatistics),
                  AsyncSection<PublicStatistics>(
                    value: statistics,
                    onRetry: () => ref.invalidate(publicStatisticsProvider),
                    builder: (BuildContext context, PublicStatistics s) =>
                        StatGrid(stats: _statsFrom(s)),
                  ),
                  AppSpacing.gapXl,
                  const SectionHeader(title: AppStrings.practicalImpact),
                  AsyncSection<List<PublicActivityCount>>(
                    value: activity,
                    isEmpty: (List<PublicActivityCount> items) =>
                        items.every((PublicActivityCount i) => i.total == 0),
                    emptyTitle: AppStrings.noPublicActivityYet,
                    emptyIcon: Icons.volunteer_activism_outlined,
                    onRetry: () => ref.invalidate(publicActivityProvider),
                    builder: (BuildContext context,
                            List<PublicActivityCount> items) =>
                        _ActivityBreakdown(items: items),
                  ),
                  AppSpacing.gapXl,
                  const SectionHeader(title: AppStrings.ourWebsite),
                  _WebsiteCard(onVisit: () => _openWebsite(context)),
                  AppSpacing.gapLg,
                  Text(
                    AppStrings.guestReadOnly,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The public figures as tiles. They are not tappable: there is nothing
/// underneath them a guest may open.
List<StatItem> _statsFrom(PublicStatistics s) {
  String n(int value) => UrduNumbers.fromInt(value);

  return <StatItem>[
    // فاضل before فاضلہ, here as everywhere.
    StatItem(
      label: AppStrings.totalMale,
      value: n(s.totalMale),
      icon: Icons.school_outlined,
    ),
    StatItem(
      label: AppStrings.totalFemale,
      value: n(s.totalFemale),
      icon: Icons.school_outlined,
      tone: StatTone.teal,
    ),
    StatItem(
      label: AppStrings.totalBoth,
      value: n(s.totalGraduates),
      icon: Icons.groups_outlined,
      tone: StatTone.olive,
    ),
    StatItem(
      label: AppStrings.totalKarGuzari,
      value: n(s.totalReports),
      icon: Icons.description_outlined,
      tone: StatTone.brown,
    ),
    StatItem(
      label: AppStrings.socialActivities,
      value: n(s.socialActivities),
      icon: Icons.volunteer_activism_outlined,
      tone: StatTone.gold,
    ),
    StatItem(
      label: AppStrings.practicalServices,
      value: n(s.practicalServices),
      icon: Icons.handshake_outlined,
      tone: StatTone.neutral,
    ),
    StatItem(
      label: AppStrings.completedProjects,
      value: n(s.completedProjects),
      icon: Icons.task_alt_outlined,
    ),
  ];
}

/// Brand mark, name and tagline, with the one action a guest has: signing in
/// properly, or signing out of the guest account.
class _Header extends StatelessWidget {
  const _Header({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.screenHorizontal,
        end: AppSpacing.screenHorizontal,
        top: AppSpacing.xxl,
        bottom: AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.darkGreen,
        borderRadius: BorderRadiusDirectional.only(
          bottomStart: Radius.circular(24),
          bottomEnd: Radius.circular(24),
        ),
      ),
      child: Row(
        children: <Widget>[
          const BrandMark(size: 56),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppConfig.appNameUrdu,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: AppColors.white),
                ),
                AppSpacing.gapXxs,
                Text(
                  AppConfig.appTaglineUrdu,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (signedIn)
            const SignOutAction()
          else
            TextButton(
              onPressed: () => context.go(AppRoutes.signIn),
              child: const Text(
                AppStrings.signIn,
                style: TextStyle(color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Category names and how much work sits under each, grouped as the
/// categories themselves are grouped.
class _ActivityBreakdown extends StatelessWidget {
  const _ActivityBreakdown({required this.items});

  final List<PublicActivityCount> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Map<String, List<PublicActivityCount>> grouped =
        <String, List<PublicActivityCount>>{};
    for (final PublicActivityCount item in items) {
      grouped
          .putIfAbsent(item.groupTitle, () => <PublicActivityCount>[])
          .add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MapEntry<String, List<PublicActivityCount>> group
            in grouped.entries) ...<Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(group.key, style: theme.textTheme.titleSmall),
          ),
          for (final PublicActivityCount item in group.value)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: AppListTile(
                title: item.categoryTitle,
                icon: Icons.check_circle_outline,
                accentColor: AppColors.oliveGreen,
                trailing: Text(
                  UrduNumbers.fromInt(item.total),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: AppColors.darkGreen),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// The invitation to the organisation's own website.
class _WebsiteCard extends StatelessWidget {
  const _WebsiteCard({required this.onVisit});

  final VoidCallback onVisit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: AppRadius.radiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(AppStrings.ourWebsite, style: theme.textTheme.titleSmall),
          AppSpacing.gapXs,
          Text(
            AppStrings.websiteInvite,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.earthBrown),
          ),
          AppSpacing.gapMd,
          PrimaryButton(
            label: AppStrings.visitWebsite,
            icon: Icons.open_in_new_rounded,
            onPressed: onVisit,
          ),
        ],
      ),
    );
  }
}
