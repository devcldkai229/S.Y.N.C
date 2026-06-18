import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/cubit/social_cubit.dart';

class SocialFeedSearchBar extends StatelessWidget {
  const SocialFeedSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Material(
        color: AppColors.backgroundAlt,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => context.push(AppRoutes.socialSearch, extra: context.read<SocialCubit>()),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tìm kiếm bài viết, người dùng...',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
