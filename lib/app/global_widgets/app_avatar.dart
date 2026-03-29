import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.avatarUrl,
    required this.radius,
    this.backgroundColor,
    this.icon,
    this.iconColor,
    this.iconSize,
  });

  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    final provider = hasAvatar ? CachedNetworkImageProvider(avatarUrl!) : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: provider,
      onBackgroundImageError: provider == null ? null : (_, __) {},
      child: provider == null
          ? Icon(
              icon ?? Icons.person,
              color: iconColor,
              size: iconSize,
            )
          : null,
    );
  }
}
