import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/profile/cubit/profile_cubit.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/shared/widgets/primary_button.dart';

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
  final _nameController = TextEditingController();
  String? _gender;
  String? _dob;
  String? _height;
  String? _weight;
  String? _fitnessGoal;
  String? _activityLevel;
  bool _fieldsInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _syncFields(ProfileSettings settings) {
    if (_fieldsInitialized) return;
    _fieldsInitialized = true;
    _nameController.text = settings.basic.fullName;
    _gender = settings.fitness.gender ?? '—';
    _dob = settings.fitness.dateOfBirth ?? '—';
    _height = settings.fitness.heightCm != null ? '${settings.fitness.heightCm!.round()} cm' : '—';
    _weight = settings.fitness.currentWeightKg != null
        ? '${settings.fitness.currentWeightKg} kg'
        : '—';
    _fitnessGoal = settings.fitness.fitnessGoal ?? '—';
    _activityLevel = settings.fitness.activityLevel ?? '—';
  }

  Future<void> _save(ProfileSettings settings) async {
    final fitness = FitnessProfile(
      isConfigured: true,
      gender: _gender == '—' ? null : _gender,
      dateOfBirth: _dob == '—' ? null : _dob,
      heightCm: _parseHeight(_height),
      currentWeightKg: _parseWeight(_weight),
      fitnessGoal: _fitnessGoal == '—' ? null : _fitnessGoal,
      activityLevel: _activityLevel == '—' ? null : _activityLevel,
    );
    await context.read<ProfileCubit>().save(
          fullName: _nameController.text.trim(),
          fitness: fitness,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
    }
  }

  double? _parseHeight(String? text) {
    if (text == null || text == '—') return null;
    final n = RegExp(r'[\d.]+').stringMatch(text);
    return n != null ? double.tryParse(n) : null;
  }

  double? _parseWeight(String? text) {
    if (text == null || text == '—') return null;
    final n = RegExp(r'[\d.]+').stringMatch(text);
    return n != null ? double.tryParse(n) : null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state.settings != null) _syncFields(state.settings!);
        if (state.status == ProfileStatus.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        final settings = state.settings;
        final inventory = state.inventory;
        final isLoading = settings == null &&
            (state.status == ProfileStatus.loading || state.status == ProfileStatus.initial);
        final hasError = settings == null && state.status == ProfileStatus.failure;
        final saving = state.status == ProfileStatus.saving;
        final level = inventory?.gamification?.currentLevel ?? 1;

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SYNC',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push(AppRoutes.notifications),
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                  ],
                ),
              ),
              if (settings != null && !settings.fitness.isConfigured)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Material(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.onboarding),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primaryGreen),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Complete your fitness profile for personalized plans.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.primaryGreen),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryGreen),
                        )
                      : hasError
                          ? _ErrorView(
                              message: state.error ?? 'Could not load profile.',
                              onRetry: () => context.read<ProfileCubit>().load(),
                            )
                          : settings == null
                              ? _ErrorView(
                                  message: 'No profile data.',
                                  onRetry: () => context.read<ProfileCubit>().load(),
                                )
                              : RefreshIndicator(
                                  color: AppColors.primaryGreen,
                                  onRefresh: () => context.read<ProfileCubit>().load(),
                                  child: ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                                    children: [
                                      _AvatarHeader(
                                        nameController: _nameController,
                                        level: level,
                                      ),
                                      const SizedBox(height: 20),
                                      _ProfileSection(
                                        title: 'Biometric Profile',
                                        icon: Icons.monitor_heart_outlined,
                                        initiallyExpanded: true,
                                        children: [
                                          _InfoRow(label: 'Gender', value: _gender ?? '—'),
                                          _InfoRow(label: 'Date of Birth', value: _dob ?? '—'),
                                          _InfoRow(label: 'Height', value: _height ?? '—'),
                                          _InfoRow(label: 'Weight', value: _weight ?? '—'),
                                          const SizedBox(height: 8),
                                          _GoalChip(label: _fitnessGoal ?? '—'),
                                          const SizedBox(height: 8),
                                          _InfoRow(
                                            label: 'Activity Level',
                                            value: _activityLevel ?? '—',
                                          ),
                                        ],
                                      ),
                                      _ProfileSection(
                                        title: 'User Preferences',
                                        icon: Icons.settings_outlined,
                                        children: [
                                          _InfoRow(
                                            label: 'Agent persona',
                                            value: settings.preferences.agentPersona.isEmpty
                                                ? '—'
                                                : settings.preferences.agentPersona,
                                          ),
                                          _InfoRow(
                                            label: 'Motivation',
                                            value: settings.preferences.motivationStyle.isEmpty
                                                ? '—'
                                                : settings.preferences.motivationStyle,
                                          ),
                                        ],
                                      ),
                                      _ProfileSection(
                                        title: 'AI Performance Insights',
                                        icon: Icons.psychology_outlined,
                                        children: [
                                          Text(
                                            settings.missingProfileHints.isEmpty
                                                ? 'Complete your fitness profile for personalized AI coaching.'
                                                : settings.missingProfileHints.join('\n'),
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: (settings.profileCompletenessPercent / 100)
                                                .clamp(0.0, 1.0),
                                            backgroundColor: AppColors.border,
                                            color: AppColors.primaryGreen,
                                            minHeight: 6,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${settings.profileCompletenessPercent}% complete',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      _ProfileSection(
                                        title: 'Gamification & Rewards',
                                        icon: Icons.emoji_events_outlined,
                                        children: [
                                          _InfoRow(
                                            label: 'Sync Coins',
                                            value:
                                                '${inventory?.gamification?.syncCoins.toStringAsFixed(0) ?? 0}',
                                          ),
                                          _InfoRow(
                                            label: 'Achievements',
                                            value: '${inventory?.totalAchievementsUnlocked ?? 0}',
                                          ),
                                          _InfoRow(
                                            label: 'Streak',
                                            value:
                                                '${inventory?.gamification?.currentStreak ?? 0} days',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      PrimaryButton(
                                        label: 'Save Changes',
                                        onPressed: () => _save(settings),
                                        isLoading: saving,
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
}

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.nameController, required this.level});

  final TextEditingController nameController;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
              child: const Icon(Icons.person, size: 48, color: AppColors.primaryGreen),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, size: 16, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Your name',
          ),
        ),
        Text(
          'Level $level Athlete',
          style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

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
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, color: AppColors.primaryGreen),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          children: children,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 16, color: AppColors.primaryGreen),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
