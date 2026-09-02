import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The awards the system can grant.
class AdminRecognitionScreen extends ConsumerWidget {
  const AdminRecognitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<RecognitionItem>(
      title: AppStrings.recognitions,
      items: ref.watch(adminRecognitionsProvider),
      onRefresh: () => ref.refresh(adminRecognitionsProvider.future),
      showSearch: false,
      searchText: (RecognitionItem item) => item.title,
      emptyIcon: Icons.workspace_premium_outlined,
      itemBuilder: (BuildContext context, RecognitionItem item) =>
          RecognitionCard(item: item),
    );
  }
}
