import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/locale/locale_cubit.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/auth/services/auth_service.dart';
import 'package:sync_app/features/profile/cubit/profile_cubit.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/widgets/profile_edit_sheets.dart';
import 'package:sync_app/shared/widgets/language_switcher.dart';
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

class _ProfileScreenBody extends StatelessWidget {
  const _ProfileScreenBody();

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
        final l10n = context.l10n;
        final g = state.inventory?.gamification;
        final level = g?.currentLevel ?? state.publicProfile?.currentLevel ?? 1;
        final xp = g?.currentXp ?? state.publicProfile?.currentXp ?? 0;
        final streak = g?.currentStreak ?? 0;
        final coins = g?.syncCoins.toInt() ?? 0;

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
                  onRefresh: () => context.read<ProfileCubit>().load(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      _AvatarHeader(
                        name: s.basic.fullName,
                        email: s.basic.email,
                        avatarUrl: s.basic.avatarUrl,
                        backgroundImageUrl: s.basic.backgroundImageUrl,
                        level: level,
                        xp: xp,
                        streak: streak,
                        coins: coins,
                        verified: s.basic.emailVerified,
                        onEditAccount: () => _editAccount(context, s.basic),
                        onPickAvatar: () => _pickAndUploadAvatar(context),
                        onPickBackground: () => _pickAndUploadBackground(context),
                      ),
                      const SizedBox(height: 12),
                      if (s.profileCompletenessPercent < 100) ...[
                        _CompletenessCard(
                          percent: s.profileCompletenessPercent,
                          hints: s.missingProfileHints,
                          onSetup: () => context.push(AppRoutes.onboarding),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _SectionCard(
                        title: l10n.sectionAccount,
                        icon: Icons.person_outline,
                        initiallyExpanded: true,
                        onEdit: () => _editAccount(context, s.basic),
                        children: [
                          _Row(l10n.fullNameLabel, s.basic.fullName),
                          _Row(l10n.emailLabel, s.basic.email),
                          _Row(l10n.timezone, s.basic.timeZone),
                          _Row(l10n.packageTier, s.basic.subscriptionTier),
                          _Row(
                            l10n.emailVerified,
                            s.basic.emailVerified ? l10n.yes : l10n.no,
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 8, bottom: 4),
                            child: LanguageSwitcher(compact: true),
                          ),
                        ],
                      ),
                      _SectionCard(
                        title: l10n.sectionFitness,
                        icon: Icons.monitor_heart_outlined,
                        onEdit: s.fitness.isConfigured
                            ? () => _editFitness(context, s.fitness)
                            : () => context.push(AppRoutes.onboarding),
                        trailing: TextButton(
                          onPressed: state.isSaving
                              ? null
                              : () => _logWeight(context, s.fitness.currentWeightKg),
                          child: Text(l10n.weightQuickAction),
                        ),
                        children: _fitnessRows(context, s.fitness, state.biometric),
                      ),
                      if (s.fitness.dailyProteinTargetGram != null)
                        _SectionCard(
                          title: l10n.sectionMacros,
                          icon: Icons.pie_chart_outline,
                          children: [
                            _Row(l10n.bmrKcal, '${s.fitness.bmr ?? state.biometric?.bmr ?? l10n.notSet} kcal'),
                            _Row(l10n.tdeeKcal, '${s.fitness.baseTdee ?? state.biometric?.baseTdee ?? l10n.notSet} kcal'),
                            _Row(l10n.proteinG, '${s.fitness.dailyProteinTargetGram} g'),
                            _Row(l10n.carbG, '${s.fitness.dailyCarbTargetGram} g'),
                            _Row(l10n.fatG, '${s.fitness.dailyFatTargetGram} g'),
                          ],
                        ),
                      _SectionCard(
                        title: l10n.sectionNutritionAi,
                        icon: Icons.restaurant_outlined,
                        onEdit: () => _editPreferences(context, s.preferences),
                        children: [
                          _ChipList(
                            label: l10n.allergies,
                            items: s.preferences.allergies.map((e) => e.allergenName).toList(),
                          ),
                          _ChipList(label: l10n.favorites, items: s.preferences.favoriteFoods),
                          _ChipList(label: l10n.disliked, items: s.preferences.dislikedFoods),
                          _Row(
                            l10n.aiCoachStyleLabel,
                            L10nEnums.agentPersona(l10n, s.preferences.agentPersona),
                          ),
                          _Row(
                            l10n.motivationStyleLabel,
                            L10nEnums.motivationStyle(l10n, s.preferences.motivationStyle),
                          ),
                          _Row(
                            l10n.dataSharing,
                            s.preferences.dataSharingConsent ? l10n.agreed : l10n.notAgreed,
                          ),
                          _Row(
                            l10n.marketing,
                            s.preferences.marketingConsent ? l10n.agreed : l10n.notAgreed,
                          ),
                        ],
                      ),
                      _SectionCard(
                        title: l10n.sectionGamification,
                        icon: Icons.emoji_events_outlined,
                        children: [
                          _Row(l10n.level, '$level'),
                          _Row('XP', '$xp'),
                          _Row(
                            'Streak',
                            '${l10n.streakDays(streak)} (${l10n.longestStreak(g?.longestStreak ?? 0)})',
                          ),
                          _Row(l10n.syncCoins, '${g?.syncCoins.toStringAsFixed(0) ?? 0}'),
                          _Row(l10n.achievementPoints, '${g?.achievementPoints ?? 0}'),
                          _Row(
                            l10n.achievementsUnlocked,
                            '${state.inventory?.totalAchievementsUnlocked ?? 0}',
                          ),
                          _Row(l10n.vouchers, '${state.inventory?.totalVouchers ?? 0}'),
                          if (state.inventory?.achievements.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
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
                      ),
                      if (state.publicProfile != null)
                        _SectionCard(
                          title: l10n.sectionPublicProfile,
                          icon: Icons.public_outlined,
                          children: [
                            _Row(l10n.displayName, state.publicProfile!.fullName),
                            _Row(l10n.level, '${state.publicProfile!.currentLevel}'),
                            _Row('XP', '${state.publicProfile!.currentXp}'),
                            _Row('Streak', l10n.streakDays(state.publicProfile!.currentStreak)),
                          ],
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.onboarding),
                        icon: const Icon(Icons.tune),
                        label: Text(l10n.fullSetupProfile),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          side: const BorderSide(color: AppColors.primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          side: BorderSide(color: Colors.red.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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

  List<Widget> _fitnessRows(
    BuildContext context,
    FitnessProfile f,
    BiometricProfileDetail? bio,
  ) {
    final l10n = context.l10n;
    final dash = l10n.notSet;
    if (!f.isConfigured) {
      return [
        Text(
          l10n.fitnessNotConfigured,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ];
    }
    return [
      _Row(l10n.genderLabel, L10nEnums.gender(l10n, f.gender)),
      _Row(l10n.dateOfBirthLabel, f.dateOfBirth ?? dash),
      _Row(
        l10n.heightCmLabel,
        f.heightCm != null ? '${f.heightCm!.toStringAsFixed(0)} cm' : dash,
      ),
      _Row(
        l10n.currentWeightKgLabel,
        f.currentWeightKg != null ? '${f.currentWeightKg} kg' : dash,
      ),
      _Row(
        l10n.targetWeightKgLabel,
        f.targetWeightKg != null ? '${f.targetWeightKg} kg' : dash,
      ),
      _Row(l10n.goalLabel, L10nEnums.fitnessGoal(l10n, f.fitnessGoal)),
      _Row(l10n.activityLabel, L10nEnums.activityLevel(l10n, f.activityLevel)),
      _Row(l10n.experienceLabel, L10nEnums.experience(l10n, f.fitnessExperienceLevel)),
      _Row(l10n.trainingLocationLabel, L10nEnums.workoutLocation(l10n, f.workoutLocationPreference)),
      if (f.injuries.isNotEmpty) _ChipList(label: l10n.injuriesLabel, items: f.injuries),
      if (f.medications.isNotEmpty) _ChipList(label: l10n.medicationsLabel, items: f.medications),
    ];
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
      SnackBar(content: Text(ok ? 'Đã cập nhật ảnh đại diện' : 'Không thể tải ảnh lên')),
    );
  }

  Future<void> _pickAndUploadBackground(BuildContext context) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !context.mounted) return;
    final ok = await context.read<ProfileCubit>().uploadAndSaveBackground(picked);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Đã cập nhật ảnh nền' : 'Không thể tải ảnh lên')),
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

  Future<void> _logWeight(BuildContext context, double? current) async {
    final kg = await showLogWeightSheet(context, current: current);
    if (kg == null || !context.mounted) return;
    await context.read<ProfileCubit>().logWeight(kg);
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Log out',
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
    required this.level,
    required this.xp,
    required this.streak,
    required this.coins,
    required this.verified,
    required this.onEditAccount,
    required this.onPickAvatar,
    required this.onPickBackground,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final String? backgroundImageUrl;
  final int level;
  final int xp;
  final int streak;
  final int coins;
  final bool verified;
  final VoidCallback onEditAccount;
  final VoidCallback onPickAvatar;
  final VoidCallback onPickBackground;

  static const _avatarRadius = 60.0;
  static const _bannerHeight = 220.0;
  static const _bannerRadius = 14.0;

  @override
  Widget build(BuildContext context) {
    final hasBackground = backgroundImageUrl != null && backgroundImageUrl!.isNotEmpty;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onPickBackground,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_bannerRadius),
                child: SizedBox(
                  width: double.infinity,
                  height: _bannerHeight,
                  child: hasBackground
                      ? CachedNetworkImage(
                          imageUrl: backgroundImageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: _bannerHeight,
                        )
                      : DecoratedBox(
                          decoration: const BoxDecoration(color: AppColors.lightGreen),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wallpaper_rounded, color: AppColors.primaryGreen),
                                const SizedBox(width: 8),
                                Text(
                                  'Đổi ảnh nền',
                                  style: TextStyle(
                                    color: AppColors.primaryGreen.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: -_avatarRadius,
              child: Center(
                child: GestureDetector(
                  onTap: onPickAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cardBackground,
                          border: Border.all(color: AppColors.cardBackground, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SyncAvatar(name: name, imageUrl: avatarUrl, radius: _avatarRadius),
                      ),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _avatarRadius + 8),
        Column(
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              if (verified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, size: 18, color: AppColors.primaryGreen),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onPickAvatar,
            icon: const Icon(Icons.camera_alt_outlined, size: 16),
            label: const Text('Đổi ảnh đại diện'),
          ),
          TextButton.icon(
            onPressed: onEditAccount,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Chỉnh sửa tài khoản'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                icon: Icons.military_tech_rounded,
                label: 'Lv.$level',
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              _StatChip(
                emoji: '🔥',
                label: '${streak}d',
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _StatChip(
                emoji: '💰',
                label: '$coins',
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.star_rounded,
                label: '$xp XP',
                color: Colors.purple.shade400,
              ),
            ],
          ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.color,
    this.icon,
    this.emoji,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null)
            Text(emoji!, style: const TextStyle(fontSize: 13))
          else if (icon != null)
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(16),
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
                      context.l10n.profileCompleteness,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.border,
                      color: AppColors.primaryGreen,
                      minHeight: 6,
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
                  fontSize: 20,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          if (hints.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...hints.take(3).map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 5, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(h, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onSetup,
              child: const Text(
                'Complete your profile →',
                style: TextStyle(
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
    this.onEdit,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  final VoidCallback? onEdit;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, color: AppColors.primaryGreen, size: 22),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?trailing,
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  tooltip: context.l10n.editTooltip,
                ),
            ],
          ),
          children: children,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipList extends StatelessWidget {
  const _ChipList({required this.label, required this.items});

  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _Row(label, context.l10n.notSet);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map(
                  (t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
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
            const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.actionRetry)),
          ],
        ),
      ),
    );
  }
}
