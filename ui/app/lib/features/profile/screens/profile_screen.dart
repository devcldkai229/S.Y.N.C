import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/locale/locale_cubit.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/profile/cubit/profile_cubit.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/widgets/profile_edit_sheets.dart';
import 'package:sync_app/shared/widgets/language_switcher.dart';

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
          return const SafeArea(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }

        if (state.settings == null) {
          return SafeArea(
            child: _ErrorView(
              message: state.error ?? context.l10n.loadProfileFailed,
              onRetry: () => context.read<ProfileCubit>().load(),
            ),
          );
        }

        final s = state.settings!;
        final l10n = context.l10n;
        final g = state.inventory?.gamification;
        final level = g?.currentLevel ?? state.publicProfile?.currentLevel ?? 1;
        final langLabel = s.basic.preferredLanguage.toLowerCase().startsWith('en')
            ? l10n.languageEnglish
            : l10n.languageVietnamese;

        return SafeArea(
          child: Column(
            children: [
              _TopBar(onRefresh: () => context.read<ProfileCubit>().load()),
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
                        level: level,
                        xp: g?.currentXp ?? state.publicProfile?.currentXp ?? 0,
                        verified: s.basic.emailVerified,
                        onEditAccount: () => _editAccount(context, s.basic),
                      ),
                      const SizedBox(height: 12),
                      _CompletenessCard(
                        percent: s.profileCompletenessPercent,
                        hints: s.missingProfileHints,
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: l10n.sectionAccount,
                        icon: Icons.person_outline,
                        onEdit: () => _editAccount(context, s.basic),
                        children: [
                          _Row(l10n.fullNameLabel, s.basic.fullName),
                          _Row(l10n.emailLabel, s.basic.email),
                          _Row(l10n.languageTitle, langLabel),
                          const Padding(
                            padding: EdgeInsets.only(top: 4, bottom: 8),
                            child: LanguageSwitcher(compact: true),
                          ),
                          _Row(l10n.timezone, s.basic.timeZone),
                          _Row(l10n.packageTier, s.basic.subscriptionTier),
                          _Row(
                            l10n.emailVerified,
                            s.basic.emailVerified ? l10n.yes : l10n.no,
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
                      if (s.fitness.dailyProteinTargetGram != null) ...[
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
                      ],
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
                          _Row('XP', '${g?.currentXp ?? 0}'),
                          _Row(
                            'Streak',
                            '${l10n.streakDays(g?.currentStreak ?? 0)} (${l10n.longestStreak(g?.longestStreak ?? 0)})',
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
                      if (state.isSaving)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.profileTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          Row(
            children: [
              const LanguageIconToggle(),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: context.l10n.refreshTooltip,
              ),
              IconButton(
                onPressed: () => context.push(AppRoutes.notifications),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
        ],
      ),
    );
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
    required this.level,
    required this.xp,
    required this.verified,
    required this.onEditAccount,
  });

  final String name;
  final String email;
  final int level;
  final int xp;
  final bool verified;
  final VoidCallback onEditAccount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
              ),
            ),
            GestureDetector(
              onTap: onEditAccount,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          'Level $level · $xp XP${verified ? '' : context.l10n.emailUnverifiedSuffix}',
          style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({required this.percent, required this.hints});

  final int percent;
  final List<String> hints;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.profileCompleteness, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('$percent%', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.border,
            color: AppColors.primaryGreen,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          if (hints.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...hints.take(3).map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $h', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
    this.onEdit,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
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
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, color: AppColors.primaryGreen, size: 22),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null) trailing!,
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
