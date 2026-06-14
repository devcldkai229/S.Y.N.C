import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/core/config/aws_map_config.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/context_navigation.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/challenges/models/challenge_mock_data.dart';
import 'package:sync_app/features/challenges/models/challenge_models.dart';
import 'package:sync_app/features/challenges/state/challenge_join_state.dart';
import 'package:sync_app/features/challenges/widgets/aws_location_map.dart';
import 'package:sync_app/features/challenges/widgets/challenge_info_card.dart';
import 'package:sync_app/features/challenges/widgets/challenge_join_flow.dart';
import 'package:sync_app/features/challenges/widgets/challenge_list_tile.dart';
import 'package:sync_app/features/challenges/widgets/challenge_map_marker.dart';
import 'package:sync_app/shared/widgets/app_bottom_nav_bar.dart';
import 'package:sync_app/shared/widgets/app_shell_overlay_scaffold.dart';

/// Community challenges map + draggable challenge list with global bottom nav.
class ChallengesMapScreen extends StatefulWidget {
  const ChallengesMapScreen({super.key, this.focusChallengeId});

  final String? focusChallengeId;

  @override
  State<ChallengesMapScreen> createState() => _ChallengesMapScreenState();
}

class _ChallengesMapScreenState extends State<ChallengesMapScreen> {
  /// Min fraction must fit the fixed sheet header (~100px); 0.15 caused ~4px overflow on common phones.
  static const _sheetMin = 0.22;
  static const _sheetInitial = 0.35;
  static const _sheetMax = 0.85;

  ChallengeJoinState get _joinState => getIt<ChallengeJoinState>();
  final _sheetController = DraggableScrollableController();
  final _mapKey = GlobalKey<AwsLocationMapState>();

  ChallengeFilter _filter = ChallengeFilter.all;

  List<MockChallenge> get _filteredChallenges {
    if (_filter == ChallengeFilter.all) return mockChallenges;
    return mockChallenges.where((c) => c.filter == _filter).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.focusChallengeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final challenge = challengeById(widget.focusChallengeId!);
        if (challenge != null) _focusChallenge(challenge);
      });
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _focusChallenge(MockChallenge challenge) {
    _mapKey.currentState?.moveTo(challenge.location, zoom: 14);
    _showInfoSheet(challenge);
  }

  void _expandChallengeSheet() {
    if (!_sheetController.isAttached) return;
    _sheetController.animateTo(
      _sheetMax,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  double _listBottomPadding(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return kAppBottomNavBarHeight + safeBottom + 16;
  }

  Future<void> _centerOnUserLocation() async {
    final mapState = _mapKey.currentState;
    if (mapState == null) return;

    final result = await mapState.centerOnUserLocation();
    if (!mounted) return;

    switch (result) {
      case UserLocationCenterResult.success:
        break;
      case UserLocationCenterResult.gpsDisabled:
        await _showLocationPromptDialog(
          title: kIsWeb ? 'Cho phép định vị' : 'Bật định vị',
          message: kIsWeb
              ? 'Trình duyệt chưa cho phép truy cập vị trí. '
                  'Nhấn biểu tượng khóa/cài đặt trang bên trái thanh địa chỉ, '
                  'bật "Vị trí" cho localhost rồi thử lại.'
              : 'GPS đang tắt. Vui lòng bật dịch vụ định vị để xem vị trí hiện tại của bạn trên bản đồ.',
          openSettingsLabel: kIsWeb ? 'Thử lại' : 'Bật GPS',
          onOpenSettings: kIsWeb
              ? () async {
                  await Geolocator.requestPermission();
                  return true;
                }
              : Geolocator.openLocationSettings,
          retryLocation: kIsWeb,
        );
      case UserLocationCenterResult.permissionDenied:
        if (kIsWeb) {
          await _showLocationPromptDialog(
            title: 'Cho phép định vị',
            message:
                'Trình duyệt đã từ chối quyền vị trí. '
                'Mở cài đặt trang (biểu tượng khóa trên thanh URL) và cho phép "Vị trí".',
            openSettingsLabel: 'Thử lại',
            onOpenSettings: () async {
              await Geolocator.requestPermission();
              return true;
            },
            retryLocation: true,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cần quyền truy cập vị trí để định vị trên bản đồ.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      case UserLocationCenterResult.permissionDeniedForever:
        await _showLocationPromptDialog(
          title: 'Cấp quyền vị trí',
          message:
              'Ứng dụng chưa được phép truy cập vị trí. Hãy bật quyền trong Cài đặt để sử dụng định vị.',
          openSettingsLabel: 'Mở Cài đặt',
          onOpenSettings: Geolocator.openAppSettings,
        );
      case UserLocationCenterResult.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lấy vị trí hiện tại. Vui lòng thử lại.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _showLocationPromptDialog({
    required String title,
    required String message,
    required String openSettingsLabel,
    required Future<bool> Function() onOpenSettings,
    bool retryLocation = false,
  }) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: Text(openSettingsLabel),
          ),
        ],
      ),
    );

    if (open == true) {
      await onOpenSettings();
      if (retryLocation && mounted) {
        await _centerOnUserLocation();
      }
    }
  }

  void _showInfoSheet(MockChallenge challenge) {
    _joinState.refreshStatus(challenge.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.48,
        minChildSize: 0.36,
        maxChildSize: 0.78,
        expand: false,
        builder: (_, scrollController) => ListenableBuilder(
          listenable: _joinState,
          builder: (context, _) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(ctx).bottom + 8,
            ),
            child: ChallengeInfoCard(
                challenge: challenge,
                joinState: _joinState,
                onViewRoute: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.challengeRoute(challenge.id));
                },
                onViewDetail: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.challengeDetail(challenge.id));
                },
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShellOverlayScaffold(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => context.popOrGoHome(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textPrimary,
          ),
          title: const Text(
            'Thử thách cộng đồng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _centerOnUserLocation,
              icon: const Icon(Icons.my_location_rounded),
              color: AppColors.primaryGreen,
              tooltip: 'Vị trí của tôi',
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: AwsLocationMap(
                key: _mapKey,
                initialCenter: LatLng(AwsMapConfig.defaultLat, AwsMapConfig.defaultLng),
                onGpsDisabled: () => _showLocationPromptDialog(
                  title: kIsWeb ? 'Cho phép định vị' : 'Bật định vị',
                  message: kIsWeb
                      ? 'Trình duyệt chưa cho phép truy cập vị trí. '
                          'Bật quyền "Vị trí" cho trang này trên thanh địa chỉ.'
                      : 'Dịch vụ định vị đang tắt trong Cài đặt hệ thống. '
                          'Hãy bật Location để xem vị trí thật của bạn trên bản đồ.',
                  openSettingsLabel: kIsWeb ? 'Thử lại' : 'Mở Cài đặt',
                  onOpenSettings: kIsWeb
                      ? () async {
                          await Geolocator.requestPermission();
                          return true;
                        }
                      : Geolocator.openLocationSettings,
                  retryLocation: kIsWeb,
                ),
                markers: mockChallenges
                    .map(
                      (c) => MapMarkerData(
                        id: c.id,
                        point: c.location,
                        alignment: Alignment.center,
                        width: 44,
                        height: 44,
                        annotationLabel: c.goalEmoji,
                        annotationColor: AppColors.primaryGreen,
                        child: ChallengeMapMarker(challenge: c, compact: true),
                        onTap: () => _showInfoSheet(c),
                      ),
                    )
                    .toList(),
              ),
            ),
            _ChallengesDraggableSheet(
              controller: _sheetController,
              minSize: _sheetMin,
              initialSize: _sheetInitial,
              maxSize: _sheetMax,
              filter: _filter,
              challenges: _filteredChallenges,
              listBottomPadding: _listBottomPadding(context),
              onFilterChanged: (f) => setState(() => _filter = f),
              onSeeAll: _expandChallengeSheet,
              onChallengeTap: (id) => context.push(AppRoutes.challengeDetail(id)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengesDraggableSheet extends StatelessWidget {
  const _ChallengesDraggableSheet({
    required this.controller,
    required this.minSize,
    required this.initialSize,
    required this.maxSize,
    required this.filter,
    required this.challenges,
    required this.listBottomPadding,
    required this.onFilterChanged,
    required this.onSeeAll,
    required this.onChallengeTap,
  });

  final DraggableScrollableController controller;
  final double minSize;
  final double initialSize;
  final double maxSize;
  final ChallengeFilter filter;
  final List<MockChallenge> challenges;
  final double listBottomPadding;
  final ValueChanged<ChallengeFilter> onFilterChanged;
  final VoidCallback onSeeAll;
  final ValueChanged<String> onChallengeTap;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      snap: true,
      snapSizes: [minSize, initialSize, maxSize],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 16,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: CustomScrollView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const _SheetDragHandle(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 4, 6),
                        child: Row(
                          children: [
                            const Text(
                              'Thử thách',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: onSeeAll,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text(
                                'Xem thêm',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ChallengeFilterChips(
                        selected: filter,
                        onSelected: onFilterChanged,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                if (challenges.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                      child: Center(
                        child: Text(
                          'Không có thử thách nào trong danh mục này.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, listBottomPadding),
                    sliver: SliverList.separated(
                      itemCount: challenges.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final challenge = challenges[index];
                        return ChallengeListTile(
                          challenge: challenge,
                          onTap: () => onChallengeTap(challenge.id),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _ChallengeFilterChips extends StatelessWidget {
  const _ChallengeFilterChips({
    required this.selected,
    required this.onSelected,
  });

  final ChallengeFilter selected;
  final ValueChanged<ChallengeFilter> onSelected;

  static const _filters = <(ChallengeFilter, String)>[
    (ChallengeFilter.all, 'Tất cả'),
    (ChallengeFilter.running, '🏃 Chạy bộ'),
    (ChallengeFilter.cycling, '🚴 Đạp xe'),
    (ChallengeFilter.calories, '🔥 Calo'),
    (ChallengeFilter.workouts, '💪 Tập luyện'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = _filters[index];
          final isSelected = selected == entry.$1;
          return FilterChip(
            label: Text(entry.$2),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(entry.$1),
            selectedColor: AppColors.primaryGreen,
            backgroundColor: AppColors.cardBackground,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primaryGreen : AppColors.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 6),
          );
        },
      ),
    );
  }
}
