import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global_widgets/loading_skeleton.dart';
import '../controllers/search_controller.dart';

class SuggestedHashtagsScreen extends GetView<SearchsController> {
  const SuggestedHashtagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending hashtags'),
      ),
      body: Obx(() {
        if (controller.isLoadingSuggestions.value &&
            controller.suggestedHashtags.isEmpty) {
          return const SearchSkeleton();
        }

        if (controller.suggestedHashtags.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.loadSuggestions,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 180),
                Center(child: Text('No hashtags found')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadSuggestions,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.suggestedHashtags.length,
            separatorBuilder: (_, __) => const SizedBox(height: 1),
            itemBuilder: (context, index) {
              return _SuggestedHashtagListTile(
                tag: controller.suggestedHashtags[index],
                controller: controller,
              );
            },
          ),
        );
      }),
    );
  }
}

class _SuggestedHashtagListTile extends StatelessWidget {
  const _SuggestedHashtagListTile({
    required this.tag,
    required this.controller,
  });

  final Map<String, dynamic> tag;
  final SearchsController controller;

  @override
  Widget build(BuildContext context) {
    final value = (tag['tag']?.toString() ?? '').trim();
    final postCount = (tag['post_count'] as num?)?.toInt() ?? 0;
    final usageCount = (tag['usage_count'] as num?)?.toInt() ?? 0;

    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Text(
          '#',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        '#$value',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('$postCount posts • $usageCount uses'),
      // trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        controller.queryCtrl.text = '#$value';
        controller.onQueryChanged('#$value');
        Get.back();
      },
    );
  }
}
