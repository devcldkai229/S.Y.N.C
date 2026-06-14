import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/widgets/social_feed_search_bar.dart';
import 'package:sync_app/shared/widgets/sync_app_bar.dart';

/// App bar + search grouped in a single white header block (Facebook-style).
class SocialFeedHeader extends StatelessWidget {
  const SocialFeedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBackground,
      child: const Column(
        children: [
          SyncAppBar(isSocialScreen: true, embedded: true),
          SocialFeedSearchBar(),
        ],
      ),
    );
  }
}
