import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/controllers/subscriber_controller.dart';
import '../core/utils/subscribe_state.dart';

class SubscriberButton extends StatefulWidget {
  final String userId;
  final double height;
  final double borderRadius;
  final bool fullWidth;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry horizontalPadding;

  const SubscriberButton({
    super.key,
    required this.userId,
    this.height = 34,
    this.borderRadius = 10,
    this.fullWidth = false,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w700,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 12),
  });

  @override
  State<SubscriberButton> createState() => _SubscriberButtonState();
}

class _SubscriberButtonState extends State<SubscriberButton> {
  final controller = Get.find<SubscriberController>();

  @override
  void initState() {
    super.initState();
    controller.loadStatus(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.getState(widget.userId);

      String text;
      Color bgColor;
      Color textColor;
      Color borderColor;

      switch (state) {
        case SubscribeState.mutual:
          text = "Subscribed";
          bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
          textColor = Theme.of(context).colorScheme.onSurface;
          borderColor = Theme.of(context).colorScheme.outline;
          break;

        case SubscribeState.subscribed:
          text = "Subscribed";
          bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
          textColor = Theme.of(context).colorScheme.onSurface;
          borderColor = Theme.of(context).colorScheme.outline;
          break;

        case SubscribeState.subscribeBack:
          text = "Subscribe Back";
          bgColor = Theme.of(context).colorScheme.primary;
          textColor = Theme.of(context).colorScheme.onPrimary;
          borderColor = Theme.of(context).colorScheme.primary;
          break;

        case SubscribeState.none:
          text = "Subscribe";
          bgColor = Theme.of(context).colorScheme.primary;
          textColor = Theme.of(context).colorScheme.onPrimary;
          borderColor = Theme.of(context).colorScheme.primary;
      }

      final borderRadius = BorderRadius.circular(widget.borderRadius);

      final button = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () => controller.toggle(widget.userId),
          child: Ink(
            height: widget.height,
            padding: widget.horizontalPadding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontWeight: widget.fontWeight,
                  fontSize: widget.fontSize,
                ),
              ),
            ),
          ),
        ),
      );

      if (!widget.fullWidth) {
        return button;
      }

      return SizedBox(width: double.infinity, child: button);

      /*return ElevatedButton(
        onPressed: () => controller.toggle(widget.userId),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
        ),
        child: Text(
          text,
          style: TextStyle(color: textColor),
        ),
      );*/
    });
  }
}


/*class SubscriberButton extends StatelessWidget {
  final String userId;

  const SubscriberButton({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriberController>();

    controller.checkStatus(userId);

    return Obx(() {
      final isSubscribed = controller.isSubscribed(userId);

      return ElevatedButton(
        onPressed: () => controller.toggle(userId),
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isSubscribed ? Colors.grey[300] : Colors.blue,
        ),
        child: Text(
          isSubscribed ? "Subscribed" : "Subscribe",
          style: TextStyle(
            color: isSubscribed ? Colors.black : Colors.white,
          ),
        ),
      );
    });
  }
}*/
