import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/controllers/post_story_style_controller.dart';

class ContentStyleSettingsScreen extends GetView<PostStoryStyleController> {
  const ContentStyleSettingsScreen({super.key});

  static const List<Color> _palette = [
    Colors.transparent,
    Colors.white,
    Color(0xFFF6F7FB),
    Color(0xFF111827),
    Color(0xFF0B3D2E),
    Color(0xFF4A044E),
    Colors.black,
    Colors.blue,
    Colors.indigo,
    Colors.teal,
    Colors.orange,
    Colors.redAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post & Story Style'),
        actions: [
          TextButton(
            onPressed: controller.resetDefaults,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _sectionTitle('Post'),
            _sliderTile(
              title: 'Post corner radius',
              value: controller.postCornerRadius.value,
              min: 0,
              max: 24,
              onChanged: controller.setPostCornerRadius,
            ),
            _sliderTile(
              title: 'Action icon size',
              value: controller.postActionIconSize.value,
              min: 22,
              max: 34,
              onChanged: controller.setPostActionIconSize,
            ),
            _colorTile(
              title: 'Post background color',
              selectedColor: controller.postBackgroundColor,
              onColorSelected: controller.setPostBackgroundColor,
            ),
            const SizedBox(height: 18),
            _sectionTitle('Story'),
            _sliderTile(
              title: 'Story card width',
              value: controller.storyCardWidth.value,
              min: 72,
              max: 110,
              onChanged: controller.setStoryCardWidth,
            ),
            _sliderTile(
              title: 'Avatar size',
              value: controller.storyAvatarRadius.value,
              min: 28,
              max: 44,
              onChanged: controller.setStoryAvatarRadius,
            ),
            _colorTile(
              title: 'Story label color',
              selectedColor: controller.storyLabelColor,
              onColorSelected: controller.setStoryLabelColor,
            ),
            _colorTile(
              title: 'Story ring start color',
              selectedColor: controller.storyRingStartColor,
              onColorSelected: controller.setStoryRingStartColor,
            ),
            _colorTile(
              title: 'Story ring end color',
              selectedColor: controller.storyRingEndColor,
              onColorSelected: controller.setStoryRingEndColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _sliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${value.toStringAsFixed(1)})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _colorTile({
    required String title,
    required Color selectedColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palette.map((color) {
              final isSelected = selectedColor.toARGB32() == color.toARGB32();
              final borderColor = isSelected
                  ? Colors.blue
                  : Colors.grey.withValues(alpha: 0.35);

              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color == Colors.transparent ? Colors.white : color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: color == Colors.transparent
                      ? const Icon(Icons.block, size: 14, color: Colors.black54)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
