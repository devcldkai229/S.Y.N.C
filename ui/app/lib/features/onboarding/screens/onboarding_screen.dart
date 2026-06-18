import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/models/onboarding_models.dart';
import 'package:sync_app/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:sync_app/features/onboarding/data/onboarding_tag_catalog.dart';
import 'package:sync_app/features/onboarding/widgets/searchable_tag_field.dart';
import 'package:sync_app/shared/widgets/custom_text_field.dart';
import 'package:sync_app/shared/widgets/primary_button.dart';
import 'package:sync_app/shared/widgets/progress_header.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  String _gender = 'Male';
  DateTime _dateOfBirth = DateTime(1995, 1, 1);
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '70');
  final _targetWeightController = TextEditingController(text: '68');

  String _fitnessGoal = 'LoseFat';
  String _activityLevel = 'ModeratelyActive';
  String _experience = 'Intermediate';
  String _location = 'Gym';

  List<String> _injuries = [];
  List<String> _allergies = [];
  List<String> _favoriteFoods = [];
  List<String> _dislikedFoods = [];

  String _agentPersona = 'FriendlyBuddy';
  String _motivationStyle = 'Supportive';
  bool _dataSharingConsent = false;
  bool _marketingConsent = false;

  String? _localError;

  @override
  void initState() {
    super.initState();
    for (final c in [_heightController, _weightController, _targetWeightController]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _sideAValid {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final target = double.tryParse(_targetWeightController.text);
    return height != null &&
        height > 0 &&
        weight != null &&
        weight > 0 &&
        target != null &&
        target > 0;
  }

  bool get _sideBValid =>
      _allergies.isNotEmpty &&
      _dataSharingConsent &&
      _marketingConsent;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(getIt()),
      child: BlocListener<OnboardingCubit, OnboardingState>(
        listenWhen: (p, c) =>
            p.sideACompleted != c.sideACompleted || p.isCompleted != c.isCompleted,
        listener: (context, state) {
          if (state.sideACompleted && _page == 0) {
            setState(() => _page = 1);
            _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            );
          }
          if (state.isCompleted) context.go(AppRoutes.home);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                ProgressHeader(
                  currentStep: _page + 1,
                  totalSteps: 2,
                  onClose: () {
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_sideA(), _sideB()],
                  ),
                ),
                BlocBuilder<OnboardingCubit, OnboardingState>(
                  builder: (context, state) {
                    final canProceed = _page == 0 ? _sideAValid : _sideBValid;
                    final error = _localError ?? state.error;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        children: [
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                error,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          PrimaryButton(
                            label: _page == 0
                                ? context.l10n.actionContinue
                                : context.l10n.actionFinishSetup,
                            isLoading: state.isSubmitting,
                            onPressed: (!canProceed || state.isSubmitting)
                                ? () {}
                                : () => _onPrimaryPressed(context),
                          ),
                          if (_page == 1) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _page = 0;
                                        _localError = null;
                                      });
                                      _pageController.animateToPage(
                                        0,
                                        duration: const Duration(milliseconds: 280),
                                        curve: Curves.easeOut,
                                      );
                                    },
                              child: Text(context.l10n.actionBack),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sideA() {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingSideATitle,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingSideASubtitle,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _labeledDropdown(
            l10n.genderLabel,
            _gender,
            L10nEnums.genderOptions(l10n),
            (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 16),
          _dateOfBirthField(),
          const SizedBox(height: 16),
          CustomTextField(
            label: l10n.heightCmLabel,
            controller: _heightController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: l10n.currentWeightKgLabel,
            controller: _weightController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: l10n.targetWeightKgLabel,
            controller: _targetWeightController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _labeledDropdown(
            l10n.goalLabel,
            _fitnessGoal,
            L10nEnums.fitnessGoalOptions(l10n),
            (v) => setState(() => _fitnessGoal = v),
          ),
          const SizedBox(height: 16),
          _labeledDropdown(
            l10n.activityLabel,
            _activityLevel,
            L10nEnums.activityOptions(l10n),
            (v) => setState(() => _activityLevel = v),
          ),
          const SizedBox(height: 16),
          _labeledDropdown(
            l10n.experienceLabel,
            _experience,
            L10nEnums.experienceOptions(l10n),
            (v) => setState(() => _experience = v),
          ),
          const SizedBox(height: 16),
          _labeledDropdown(
            l10n.trainingLocationLabel,
            _location,
            L10nEnums.locationOptions(l10n),
            (v) => setState(() => _location = v),
          ),
          const SizedBox(height: 24),
          SearchableTagField(
            label: l10n.injuriesLabel,
            hint: l10n.injuriesSearchHint,
            catalog: OnboardingTagCatalog.injuries,
            popularTags: OnboardingTagCatalog.injuriesPopular,
            selected: _injuries,
            exclusiveNoneTag: OnboardingTagCatalog.noneInjury,
            onChanged: (v) => setState(() => _injuries = v),
          ),
        ],
      ),
    );
  }

  Widget _sideB() {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingSideBTitle,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingSideBSubtitle,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SearchableTagField(
            label: l10n.allergiesLabel,
            hint: l10n.allergiesSearchHint,
            catalog: OnboardingTagCatalog.allergies,
            popularTags: OnboardingTagCatalog.allergiesPopular,
            selected: _allergies,
            exclusiveNoneTag: OnboardingTagCatalog.noneAllergy,
            required: true,
            onChanged: (v) => setState(() => _allergies = v),
          ),
          const SizedBox(height: 20),
          SearchableTagField(
            label: l10n.favoriteFoodsLabel,
            hint: l10n.favoriteFoodsSearchHint,
            catalog: OnboardingTagCatalog.favoriteFoods,
            popularTags: OnboardingTagCatalog.favoriteFoodsPopular,
            selected: _favoriteFoods,
            onChanged: (v) => setState(() => _favoriteFoods = v),
          ),
          const SizedBox(height: 20),
          SearchableTagField(
            label: l10n.dislikedFoodsLabel,
            hint: l10n.dislikedFoodsSearchHint,
            catalog: OnboardingTagCatalog.dislikedFoods,
            popularTags: OnboardingTagCatalog.dislikedFoodsPopular,
            selected: _dislikedFoods,
            onChanged: (v) => setState(() => _dislikedFoods = v),
          ),
          const SizedBox(height: 20),
          _labeledDropdown(
            l10n.aiCoachStyleLabel,
            _agentPersona,
            L10nEnums.personaOptions(l10n),
            (v) => setState(() => _agentPersona = v),
          ),
          const SizedBox(height: 16),
          _labeledDropdown(
            l10n.motivationStyleLabel,
            _motivationStyle,
            L10nEnums.motivationOptions(l10n),
            (v) => setState(() => _motivationStyle = v),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _dataSharingConsent,
            onChanged: (v) => setState(() => _dataSharingConsent = v ?? false),
            title: Text(
              l10n.consentDataSharing,
              style: const TextStyle(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            value: _marketingConsent,
            onChanged: (v) => setState(() => _marketingConsent = v ?? false),
            title: Text(
              l10n.consentMarketing,
              style: const TextStyle(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _dateOfBirthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.dateOfBirthLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dateOfBirth,
              firstDate: DateTime(1940),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 14)),
            );
            if (picked != null) setState(() => _dateOfBirth = picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(_dateOfBirth)),
                const Icon(Icons.calendar_today_outlined, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _labeledDropdown(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: options.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Future<void> _onPrimaryPressed(BuildContext context) async {
    setState(() => _localError = null);
    final cubit = context.read<OnboardingCubit>();

    if (_page == 0) {
      if (!_sideAValid) {
        setState(() => _localError = context.l10n.onboardingValidationRequired);
        return;
      }
      final injuries = _injuries
          .where((t) => t != OnboardingTagCatalog.noneInjury)
          .toList();
      await cubit.submitSideA(
        basic: OnboardingStep1Request(
          gender: _gender,
          dateOfBirth: _formatDate(_dateOfBirth),
          heightCm: double.parse(_heightController.text),
        ),
        goals: OnboardingStep2Request(
          currentWeightKg: double.parse(_weightController.text),
          targetWeightKg: double.parse(_targetWeightController.text),
          fitnessGoal: _fitnessGoal,
          activityLevel: _activityLevel,
          fitnessExperienceLevel: _experience,
          workoutLocationPreference: _location,
        ),
        safeguards: OnboardingStep4Request(injuries: injuries),
      );
      return;
    }

    if (!_sideBValid) {
      setState(() => _localError = context.l10n.onboardingValidationAllergies);
      return;
    }

    final allergies = _allergies
        .where((t) => t != OnboardingTagCatalog.noneAllergy)
        .toList();
    if (allergies.isEmpty && _allergies.contains(OnboardingTagCatalog.noneAllergy)) {
      allergies.add(OnboardingTagCatalog.noneAllergy);
    }

    await cubit.submitSideB(
      OnboardingAccountPreferencesRequest(
        allergies: allergies.isEmpty ? _allergies : allergies,
        favoriteFoods: _favoriteFoods,
        dislikedFoods: _dislikedFoods,
        agentPersona: _agentPersona,
        motivationStyle: _motivationStyle,
        dataSharingConsent: _dataSharingConsent,
        marketingConsent: _marketingConsent,
      ),
    );
  }
}
