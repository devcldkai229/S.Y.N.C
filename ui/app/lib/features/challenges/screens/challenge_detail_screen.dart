import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/context_navigation.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/challenges/models/challenge_mock_data.dart';
import 'package:sync_app/features/challenges/models/challenge_models.dart';
import 'package:sync_app/features/challenges/state/challenge_join_state.dart';
import 'package:sync_app/features/challenges/widgets/aws_location_map.dart';
import 'package:sync_app/features/challenges/widgets/challenge_join_flow.dart';
import 'package:sync_app/features/challenges/widgets/challenge_map_marker.dart';
import 'package:sync_app/features/challenges/widgets/challenge_rewards_section.dart';

class ChallengeDetailScreen extends StatefulWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  bool _descriptionExpanded = false;

  MockChallenge? get _challenge => challengeById(widget.challengeId);
  ChallengeJoinState get _joinState => getIt<ChallengeJoinState>();

  @override
  void initState() {
    super.initState();
    _joinState.refreshStatus(widget.challengeId);
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    if (challenge == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thử thách')),
        body: const Center(child: Text('Không tìm thấy thử thách')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.popOrGoHome(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
        ),
        title: const Text(
          'Chi tiết thử thách',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ),
      body: ListenableBuilder(
        listenable: _joinState,
        builder: (context, _) {
          final joined = _joinState.isJoined(challenge.id);
          final loading = _joinState.isLoading(challenge.id);
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MapPreview(challenge: challenge),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Transform.translate(
                          offset: const Offset(0, -24),
                          child: _InfoCard(challenge: challenge),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mô tả',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            _ExpandableDescription(
                              text: challenge.description,
                              expanded: _descriptionExpanded,
                              onToggle: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
                            ),
                            if (challenge.pointRewards > 0 || challenge.gifts.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              ChallengeRewardsSection(
                                pointRewards: challenge.pointRewards,
                                gifts: challenge.gifts,
                              ),
                            ],
                            const SizedBox(height: 20),
                            const Text(
                              'Người tham gia',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            _ParticipantsPreview(count: challenge.participantCount),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _ActionBar(
                joined: joined,
                loading: loading,
                onJoin: () => ChallengeJoinFlow.confirmJoin(
                  context,
                  challenge: challenge,
                  joinState: _joinState,
                ),
                onLeave: () => ChallengeJoinFlow.confirmLeave(
                  context,
                  challenge: challenge,
                  joinState: _joinState,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.challenge});

  final MockChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          child: AwsLocationMap(
            initialCenter: challenge.location,
            initialZoom: 14,
            interactive: false,
            showUserLocation: false,
            markers: [
              MapMarkerData(
                id: challenge.id,
                point: challenge.location,
                alignment: Alignment.center,
                width: 44,
                height: 44,
                annotationLabel: challenge.goalEmoji,
                child: ChallengeMapMarker(challenge: challenge, compact: true),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 28,
          child: FilledButton.tonal(
            onPressed: () => context.push(
              '${AppRoutes.challengesMap}?focus=${challenge.id}',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
            child: const Text('Xem trên bản đồ'),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.challenge});

  final MockChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challenge.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(challenge.statusLabel, style: const TextStyle(fontSize: 13, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(challenge.goalSummary, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(challenge.dateRangeText, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(child: Text(challenge.address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            ],
          ),
          const SizedBox(height: 8),
          Text('👥 ${challenge.participantCount} người đang tham gia', style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatelessWidget {
  const _ExpandableDescription({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: expanded ? null : 3,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              expanded ? 'Thu gọn' : 'Xem thêm',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticipantsPreview extends StatelessWidget {
  const _ParticipantsPreview({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final others = (count - participantAvatarUrls.length).clamp(0, 9999);
    return Row(
      children: [
        SizedBox(
          width: participantAvatarUrls.length * 26.0 + 12,
          height: 36,
          child: Stack(
            children: [
              for (var i = 0; i < participantAvatarUrls.length; i++)
                Positioned(
                  left: i * 26.0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.borderLight,
                    backgroundImage: CachedNetworkImageProvider(participantAvatarUrls[i]),
                  ),
                ),
            ],
          ),
        ),
        Text(
          '+$others người khác',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.joined,
    required this.loading,
    required this.onJoin,
    required this.onLeave,
  });

  final bool joined;
  final bool loading;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.8))),
      ),
      child: loading
          ? const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          : joined
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Đã đăng ký tham gia',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: onLeave,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hủy đăng ký', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                )
              : FilledButton(
                  onPressed: onJoin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tham gia thử thách', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
    );
  }
}
