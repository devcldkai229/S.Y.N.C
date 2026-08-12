import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/locale/locale_cubit.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/auth/services/auth_service.dart';
import 'package:sync_app/features/profile/cubit/profile_cubit.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/widgets/profile_edit_sheets.dart';
import 'package:sync_app/features/social/models/follow_models.dart';
import 'package:sync_app/shared/widgets/sync_app_bar.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(getIt())..load(),
      child: const _ProfileScreenBody(),
    );
  }
}

class _ProfileScreenBody extends StatefulWidget {
  const _ProfileScreenBody();

  @override
  State<_ProfileScreenBody> createState() => _ProfileScreenBodyState();
}

class _ProfileScreenBodyState extends State<_ProfileScreenBody> {
  final _socialRepo = getIt<SocialRepository>();

  FollowCounts _followCounts = FollowCounts.empty;
  String? _followLoadedForUserId;

  Future<void> _loadFollowCounts(String userId) async {
    if (userId.isEmpty) return;
    try {
      final counts = await _socialRepo.loadFollowCounts(userId);
      if (!mounted) return;
      setState(() {
        _followLoadedForUserId = userId;
        _followCounts = counts;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _followLoadedForUserId = userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (p, c) =>
          (p.status == ProfileStatus.saving && c.status == ProfileStatus.success) ||
          (p.status != ProfileStatus.failure && c.status == ProfileStatus.failure),
      listener: (context, state) {
        if (state.status == ProfileStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.savedSuccessfully)),
          );
        }
        if (state.status == ProfileStatus.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            appBar: SyncAppBar(),
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }

        if (state.settings == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: const SyncAppBar(),
            body: SafeArea(
              top: false,
              child: _ErrorView(
                message: state.error ?? context.l10n.loadProfileFailed,
                onRetry: () => context.read<ProfileCubit>().load(),
              ),
            ),
          );
        }

        final s = state.settings!;
        final userId = s.userId;
        if (userId.isNotEmpty && userId != _followLoadedForUserId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && userId != _followLoadedForUserId) {
              _loadFollowCounts(userId);
            }
          });
        }

        final l10n = context.l10n;
        final g = state.inventory?.gamification;
        final level = g?.currentLevel ?? state.publicProfile?.currentLevel ?? 1;
        final xp = g?.currentXp ?? state.publicProfile?.currentXp ?? 0;
        final streak = g?.currentStreak ?? 0;
        final coins = g?.syncCoins.toInt() ?? 0;
        final voucherCount = state.inventory?.totalVouchers ?? 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const SyncAppBar(),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                if (!s.fitness.isConfigured || !s.preferences.isConfigured)
                  _SetupBanner(
                    onSetup: () => context.push(AppRoutes.onboarding),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () async {
                      await context.read<ProfileCubit>().load();
                      await _loadFollowCounts(userId);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      children: [
                        _AvatarHeader(
                          name: s.basic.fullName,
                          email: s.basic.email,
                          avatarUrl: s.basic.avatarUrl,
                          backgroundImageUrl: s.basic.backgroundImageUrl,
                          tier: s.basic.subscriptionTier,
                          verified: s.basic.emailVerified,
                          onEdit: () => _editAccount(context, s.basic),
                          onPickAvatar: () => _pickAndUploadAvatar(context),
                          onPickBackground: () => _pickAndUploadBackground(context),
                        ),
                        const SizedBox(height: 16),
                        _StatStrip(
                          level: level,
                          streak: streak,
                          coins: coins,
                          xp: xp,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.push(
                                  AppRoutes.socialUserFollowers(userId),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryGreen,
                                  side: const BorderSide(color: AppColors.border),
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l10n.profileFollowersBtn(_followCounts.followerCount),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.push(
                                  AppRoutes.socialUserFollowing(userId),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryGreen,
                                  side: const BorderSide(color: AppColors.border),
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l10n.profileFollowingBtn(_followCounts.followingCount),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (s.profileCompletenessPercent < 100) ...[
                          const SizedBox(height: 16),
                          _CompletenessCard(
                            percent: s.profileCompletenessPercent,
                            hints: s.missingProfileHints,
                            onSetup: () => context.push(AppRoutes.onboarding),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _SettingsGroup(
                          title: l10n.profileGroupPersonalize,
                          children: [
                            _SettingsRow(
                              icon: Icons.monitor_heart_outlined,
                              title: l10n.sectionFitness,
                              subtitle: s.fitness.isConfigured
                                  ? L10nEnums.fitnessGoal(l10n, s.fitness.fitnessGoal)
                                  : l10n.fitnessNotConfigured,
                              onTap: () {
                                if (s.fitness.isConfigured) {
                                  _editFitness(context, s.fitness);
                                } else {
                                  context.push(AppRoutes.onboarding);
                                }
                              },
                            ),
                            if (s.fitness.dailyProteinTargetGram != null)
                              _SettingsRow(
                                icon: Icons.pie_chart_outline,
                                title: l10n.profileMacrosDaily,
                                subtitle:
                                    'P ${s.fitness.dailyProteinTargetGram} · C ${s.fitness.dailyCarbTargetGram} · F ${s.fitness.dailyFatTargetGram}',
                                onTap: () => _showMacrosSheet(context, s.fitness, state.biometric),
                              ),
                            _SettingsRow(
                              icon: Icons.restaurant_outlined,
                              title: l10n.sectionNutritionAi,
                              subtitle: L10nEnums.agentPersona(
                                l10n,
                                s.preferences.agentPersona,
                              ),
                              onTap: () => _editPreferences(context, s.preferences),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SettingsGroup(
                          title: l10n.profileGroupActivity,
                          children: [
                            _SettingsRow(
                              icon: Icons.emoji_events_outlined,
                              title: l10n.sectionGamification,
                              subtitle: '${l10n.level} $level · ${l10n.streakDays(streak)}',
                              onTap: () => _showGamificationSheet(context, state),
                            ),
                            _SettingsRow(
                              icon: Icons.local_offer_outlined,
                              title: l10n.profileVouchersTitle,
                              subtitle: voucherCount == 0
                                  ? l10n.profileNoVouchersShort
                                  : l10n.profileVoucherCount(voucherCount),
                              onTap: () => _showVouchersSheet(
                                context,
                                state.inventory?.vouchers ?? const [],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SettingsGroup(
                          title: l10n.profileGroupAccount,
                          children: [
                            if (state.publicProfile != null)
                              _SettingsRow(
                                icon: Icons.public_outlined,
                                title: l10n.sectionPublicProfile,
                                subtitle: state.publicProfile!.fullName,
                                onTap: () => _showPublicProfileSheet(
                                  context,
                                  state.publicProfile!,
                                ),
                              ),
                            _SettingsRow(
                              icon: Icons.tune_outlined,
                              title: l10n.fullSetupProfile,
                              onTap: () => context.push(AppRoutes.onboarding),
                            ),
                            _SettingsRow(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Chính sách bảo mật',
                              onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
                            ),
                            _SettingsRow(
                              icon: Icons.description_outlined,
                              title: 'Điều khoản sử dụng',
                              onTap: () => _openUrl(AppConfig.termsOfServiceUrl),
                            ),
                            _SettingsRow(
                              icon: Icons.local_hospital_outlined,
                              title: 'Miễn trừ y tế',
                              onTap: () => _openUrl(AppConfig.healthDisclaimerUrl),
                            ),
                            _SettingsRow(
                              icon: Icons.people_outline,
                              title: 'Tiêu chuẩn cộng đồng',
                              onTap: () => _openUrl(AppConfig.communityStandardsUrl),
                            ),
                            _SettingsRow(
                              icon: Icons.mail_outline,
                              title: 'Liên hệ & pháp nhân',
                              onTap: () => _openUrl(AppConfig.contactUrl),
                            ),
                            _SettingsRow(
                              icon: Icons.delete_forever_outlined,
                              title: 'Xoá tài khoản',
                              subtitle: 'Ẩn danh dữ liệu & thu hồi phiên',
                              onTap: () => context.push(AppRoutes.deleteAccount),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => _logout(context),
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: Text(l10n.profileLogout),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade400,
                              side: BorderSide(color: Colors.red.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showDetailSheet({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.65,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMacrosSheet(
    BuildContext context,
    FitnessProfile fitness,
    BiometricProfileDetail? bio,
  ) {
    final l10n = context.l10n;
    return _showDetailSheet(
      context: context,
      title: l10n.profileMacrosDaily,
      children: [
        _DetailRow(l10n.bmrKcal, '${fitness.bmr ?? bio?.bmr ?? l10n.notSet} kcal'),
        _DetailRow(l10n.tdeeKcal, '${fitness.baseTdee ?? bio?.baseTdee ?? l10n.notSet} kcal'),
        _DetailRow(l10n.proteinG, '${fitness.dailyProteinTargetGram} g'),
        _DetailRow(l10n.carbG, '${fitness.dailyCarbTargetGram} g'),
        _DetailRow(l10n.fatG, '${fitness.dailyFatTargetGram} g'),
      ],
    );
  }

  Future<void> _showGamificationSheet(BuildContext context, ProfileState state) {
    final l10n = context.l10n;
    final g = state.inventory?.gamification;
    final level = g?.currentLevel ?? state.publicProfile?.currentLevel ?? 1;
    final xp = g?.currentXp ?? state.publicProfile?.currentXp ?? 0;
    final streak = g?.currentStreak ?? 0;

    return _showDetailSheet(
      context: context,
      title: l10n.sectionGamification,
      children: [
        _DetailRow(l10n.level, '$level'),
        _DetailRow(l10n.profileStatXp, '$xp'),
        _DetailRow(
          l10n.profileStatStreak,
          '${l10n.streakDays(streak)} (${l10n.longestStreak(g?.longestStreak ?? 0)})',
        ),
        _DetailRow(l10n.syncCoins, '${g?.syncCoins.toStringAsFixed(0) ?? 0}'),
        _DetailRow(l10n.achievementPoints, '${g?.achievementPoints ?? 0}'),
        _DetailRow(
          l10n.achievementsUnlocked,
          '${state.inventory?.totalAchievementsUnlocked ?? 0}',
        ),
        _DetailRow(l10n.vouchers, '${state.inventory?.totalVouchers ?? 0}'),
        if (state.inventory?.achievements.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(
            l10n.recentAchievements,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          ...state.inventory!.achievements.take(3).map(
                (a) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.achievementXp(a.name, a.xpReward),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  Future<void> _showVouchersSheet(BuildContext context, List<VoucherItem> vouchers) {
    final l10n = context.l10n;
    return _showDetailSheet(
      context: context,
      title: l10n.profileVouchersTitle,
      children: vouchers.isEmpty
          ? [
              Text(
                l10n.profileVouchersEmpty,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ]
          : vouchers.map((v) => _VoucherTile(voucher: v)).toList(),
    );
  }

  Future<void> _showPublicProfileSheet(BuildContext context, PublicProfile profile) {
    final l10n = context.l10n;
    return _showDetailSheet(
      context: context,
      title: l10n.sectionPublicProfile,
      children: [
        _DetailRow(l10n.displayName, profile.fullName),
        _DetailRow(l10n.level, '${profile.currentLevel}'),
        _DetailRow(l10n.profileStatXp, '${profile.currentXp}'),
        _DetailRow(l10n.profileStatStreak, l10n.streakDays(profile.currentStreak)),
      ],
    );
  }

  Future<void> _editAccount(BuildContext context, BasicProfile basic) async {
    final data = await showBasicProfileEditor(context, basic);
    if (data == null || !context.mounted) return;
    await context.read<LocaleCubit>().changeLanguage(data.language);
    if (!context.mounted) return;
    await context.read<ProfileCubit>().saveBasic(
          fullName: data.fullName,
          preferredLanguage: data.language,
          timeZone: data.timeZone,
        );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !context.mounted) return;
    final ok = await context.read<ProfileCubit>().uploadAndSaveAvatar(picked);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? context.l10n.profileAvatarUpdated : context.l10n.profileUploadFailed),
      ),
    );
  }

  Future<void> _pickAndUploadBackground(BuildContext context) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !context.mounted) return;
    final ok = await context.read<ProfileCubit>().uploadAndSaveBackground(picked);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? context.l10n.profileCoverUpdated : context.l10n.profileUploadFailed),
      ),
    );
  }

  Future<void> _editFitness(BuildContext context, FitnessProfile fitness) async {
    final updated = await showFitnessProfileEditor(context, fitness);
    if (updated == null || !context.mounted) return;
    await context.read<ProfileCubit>().saveFitness(updated);
  }

  Future<void> _editPreferences(BuildContext context, AccountPreferences prefs) async {
    final updated = await showPreferencesEditor(context, prefs);
    if (updated == null || !context.mounted) return;
    await context.read<ProfileCubit>().savePreferences(updated);
  }

  Future<void> _logout(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.profileLogoutConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(l10n.profileLogoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel, style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.profileLogout,
              style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await getIt<AuthService>().logout();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

class _SetupBanner extends StatelessWidget {
  const _SetupBanner({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Material(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onSetup,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.profileSetupBanner,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.primaryGreen),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.backgroundImageUrl,
    required this.tier,
    required this.verified,
    required this.onEdit,
    required this.onPickAvatar,
    required this.onPickBackground,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final String? backgroundImageUrl;
  final String tier;
  final bool verified;
  final VoidCallback onEdit;
  final VoidCallback onPickAvatar;
  final VoidCallback onPickBackground;

  static const _avatarRadius = 40.0;
  static const _coverHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasBackground = backgroundImageUrl != null && backgroundImageUrl!.isNotEmpty;
    final tierLabel = tier.trim().isEmpty ? null : tier.trim();

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Semantics(
              button: true,
              label: l10n.profileChangeCover,
              child: GestureDetector(
                onTap: onPickBackground,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: _coverHeight,
                    child: hasBackground
                        ? CachedNetworkImage(
                            imageUrl: MediaUrlResolver.resolve(backgroundImageUrl)!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: _coverHeight,
                            errorWidget: (_, __, ___) =>
                                const ColoredBox(color: AppColors.lightGreen),
                          )
                        : const ColoredBox(color: AppColors.lightGreen),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.35),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPickBackground,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.photo_camera_outlined, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: -_avatarRadius,
              child: GestureDetector(
                onTap: onPickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardBackground,
                      ),
                      child: SyncAvatar(name: name, imageUrl: avatarUrl, radius: _avatarRadius),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _avatarRadius + 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 18, color: AppColors.primaryGreen),
                      ],
                      if (tierLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tierLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.profileEdit),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.level,
    required this.streak,
    required this.coins,
    required this.xp,
  });

  final int level;
  final int streak;
  final int coins;
  final int xp;

  /// Visual-only progress within a soft 1000 XP band (no domain level table).
  double get _xpProgress => (xp % 1000) / 1000.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatCell(label: l10n.profileStatLevel, value: '$level'),
              _StatCell(label: l10n.profileStatStreak, value: '$streak'),
              _StatCell(label: l10n.profileStatCoins, value: '$coins'),
              _StatCell(label: l10n.profileStatXp, value: '$xp'),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _xpProgress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.border,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(height: 1, indent: 56, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({
    required this.percent,
    required this.hints,
    required this.onSetup,
  });

  final int percent;
  final List<String> hints;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileCompleteness,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.border,
                      color: AppColors.primaryGreen,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          if (hints.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...hints.take(2).map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      h,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onSetup,
              child: Text(
                l10n.profileCompleteCta,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherTile extends StatelessWidget {
  const _VoucherTile({required this.voucher});

  final VoucherItem voucher;

  Color get _statusColor {
    final s = voucher.status.toLowerCase();
    if (voucher.isExpired || s.contains('expired') || s.contains('revoked')) {
      return Colors.red.shade400;
    }
    if (s.contains('used')) return AppColors.textMuted;
    return AppColors.primaryGreen;
  }

  String get _statusLabel {
    final s = voucher.status.toLowerCase();
    if (voucher.isExpired || s.contains('expired')) return 'Hết hạn';
    if (s.contains('revoked')) return 'Thu hồi';
    if (s.contains('used')) return 'Đã dùng';
    return 'Khả dụng';
  }

  String get _valueLabel {
    final type = voucher.promotionType.toLowerCase();
    if (type.contains('percent') || type.contains('%')) {
      return '${voucher.value.toStringAsFixed(0)}% giảm giá';
    }
    if (type.contains('fixed') || type.contains('amount')) {
      return '${voucher.value.toStringAsFixed(0)}₫ giảm giá';
    }
    return '${voucher.value.toStringAsFixed(0)} · ${voucher.promotionType}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  voucher.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            voucher.voucherCode,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _valueLabel,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          if (voucher.validUntil != null && voucher.validUntil!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'HSD: ${voucher.validUntil}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: Text(context.l10n.actionRetry),
            ),
          ],
        ),
      ),
    );
  }
}
