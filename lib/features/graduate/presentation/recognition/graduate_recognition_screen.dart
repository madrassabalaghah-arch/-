import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Awards, milestones and encouragement earned by the graduate.
class GraduateRecognitionScreen extends ConsumerWidget {
  const GraduateRecognitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<RecognitionItem>(
      title: AppStrings.recognitions,
      items: ref.watch(graduateRecognitionsProvider),
      onRefresh: () => ref.refresh(graduateRecognitionsProvider.future),
      showSearch: false,
      searchText: (RecognitionItem item) => item.title,
      emptyIcon: Icons.workspace_premium_outlined,
      itemBuilder: (BuildContext context, RecognitionItem item) =>
          RecognitionCard(item: item),
    );
  }
}
