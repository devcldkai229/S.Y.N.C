import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/challenges/models/challenge_models.dart';

class ChallengeMapMarker extends StatelessWidget {
  const ChallengeMapMarker({
    super.key,
    required this.challenge,
    this.compact = false,
  });

  final CommunityChallenge challenge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pin = Container(
          width: compact ? 40 : 44,
          height: compact ? 40 : 44,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              challenge.goalEmoji,
              style: TextStyle(fontSize: compact ? 18 : 20),
            ),
          ),
        );

    if (compact) {
      return SizedBox(width: 44, height: 44, child: Center(child: pin));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pin,
        const SizedBox(height: 4),
        Container(
            constraints: const BoxConstraints(maxWidth: 88),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              challenge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}
