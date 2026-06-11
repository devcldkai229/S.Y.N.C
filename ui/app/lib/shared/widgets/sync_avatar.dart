import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/shared/utils/random_avatar_url.dart';

/// Network avatar with initials fallback when URL is missing or fails to decode.
class SyncAvatar extends StatelessWidget {
  const SyncAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 22,
    this.onTap,
  });

  final String name;
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;

  String get _initial =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  Widget _initialsAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.lightGreen,
      child: Text(
        _initial,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.primaryGreen,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }

  Widget _multiavatar(String seed) {
    return ClipOval(
      child: RandomAvatar(
        seed,
        height: radius * 2,
        width: radius * 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final randomAvatarSeed = RandomAvatarUrl.extractSeed(url);

    final Widget child;
    if (randomAvatarSeed != null) {
      child = _multiavatar(randomAvatarSeed);
    } else if (url == null || url.isEmpty) {
      child = _initialsAvatar();
    } else {
      child = ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialsAvatar(),
          errorWidget: (_, __, ___) => _initialsAvatar(),
        ),
      );
    }

    if (onTap == null) return child;

    return InkWell(
      borderRadius: BorderRadius.circular(radius * 2),
      onTap: onTap,
      child: child,
    );
  }
}
