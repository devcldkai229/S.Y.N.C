import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/locale/locale_cubit.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/onboarding/data/onboarding_tag_catalog.dart';
import 'package:sync_app/features/onboarding/widgets/searchable_tag_field.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/shared/widgets/custom_text_field.dart';
import 'package:sync_app/shared/widgets/language_switcher.dart';
import 'package:sync_app/shared/widgets/primary_button.dart';

Future<({String fullName, String language, String timeZone})?> showBasicProfileEditor(
  BuildContext context,
  BasicProfile basic,
) async {
  final l10n = context.l10n;
  final localeCubit = context.read<LocaleCubit>();
  final nameCtrl = TextEditingController(text: basic.fullName);
  final tzCtrl = TextEditingController(text: basic.timeZone);

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.sectionAccount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            CustomTextField(label: l10n.fullNameLabel, controller: nameCtrl),
            const SizedBox(height: 12),
            const LanguageSwitcher(),
            const SizedBox(height: 12),
            CustomTextField(label: l10n.timezone, controller: tzCtrl),
            const SizedBox(height: 8),
            Text('${l10n.emailLabel}: ${basic.email}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            PrimaryButton(label: l10n.actionSave, onPressed: () => Navigator.pop(ctx, true)),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
          ],
        ),
      ),
    ),
  );

  if (saved != true) {
    nameCtrl.dispose();
    tzCtrl.dispose();
    return null;
  }

  final language = localeCubit.currentCode;
  final result = (
    fullName: nameCtrl.text.trim(),
    language: language,
    timeZone: tzCtrl.text.trim(),
  );
  nameCtrl.dispose();
  tzCtrl.dispose();
  return result;
}

Future<FitnessProfile?> showFitnessProfileEditor(
  BuildContext context,
  FitnessProfile fitness,
) async {
  return showModalBottomSheet<FitnessProfile>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _FitnessEditorSheet(initial: fitness),
  );
}

class _FitnessEditorSheet extends StatefulWidget {
  const _FitnessEditorSheet({required this.initial});

  final FitnessProfile initial;

  @override
  State<_FitnessEditorSheet> createState() => _FitnessEditorSheetState();
}

class _FitnessEditorSheetState extends State<_FitnessEditorSheet> {
  late String _gender;
  late String _goal;
  late String _activity;
  late String _experience;
  late String _location;
  late List<String> _injuries;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _targetCtrl;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _gender = f.gender ?? 'Male';
    _goal = f.fitnessGoal ?? 'LoseFat';
    _activity = f.activityLevel ?? 'ModeratelyActive';
    _experience = f.fitnessExperienceLevel ?? 'Intermediate';
    _location = f.workoutLocationPreference ?? 'Gym';
    _injuries = List<String>.from(f.injuries);
    _dobCtrl = TextEditingController(text: f.dateOfBirth ?? '1995-01-01');
    _heightCtrl = TextEditingController(text: '${f.heightCm ?? 170}');
    _weightCtrl = TextEditingController(text: '${f.currentWeightKg ?? 70}');
    _targetCtrl = TextEditingController(text: '${f.targetWeightKg ?? 68}');
  }

  @override
  void dispose() {
    _dobCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.fitnessEditorTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _enumDropdown(l10n.genderLabel, _gender, L10nEnums.genderOptions(l10n), (v) {
              setState(() => _gender = v);
            }),
            const SizedBox(height: 12),
            CustomTextField(label: l10n.dateOfBirthIsoHint, controller: _dobCtrl),
            const SizedBox(height: 12),
            CustomTextField(label: l10n.heightCmLabel, controller: _heightCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            CustomTextField(label: l10n.currentWeightKgLabel, controller: _weightCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            CustomTextField(label: l10n.targetWeightKgLabel, controller: _targetCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _enumDropdown(l10n.goalLabel, _goal, L10nEnums.fitnessGoalOptions(l10n), (v) {
              setState(() => _goal = v);
            }),
            const SizedBox(height: 12),
            _enumDropdown(l10n.activityLabel, _activity, L10nEnums.activityOptions(l10n), (v) {
              setState(() => _activity = v);
            }),
            const SizedBox(height: 12),
            _enumDropdown(l10n.experienceLabel, _experience, L10nEnums.experienceOptions(l10n), (v) {
              setState(() => _experience = v);
            }),
            const SizedBox(height: 12),
            _enumDropdown(l10n.trainingLocationLabel, _location, L10nEnums.locationOptions(l10n), (v) {
              setState(() => _location = v);
            }),
            const SizedBox(height: 16),
            SearchableTagField(
              label: l10n.injuriesLabel,
              hint: l10n.injuriesSearchHint,
              catalog: OnboardingTagCatalog.injuries,
              popularTags: OnboardingTagCatalog.injuriesPopular,
              selected: _injuries,
              exclusiveNoneTag: OnboardingTagCatalog.noneInjury,
              onChanged: (v) => setState(() => _injuries = v),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: l10n.actionSave,
              onPressed: () {
                final cleanInjuries =
                    _injuries.where((t) => t != OnboardingTagCatalog.noneInjury).toList();
                Navigator.pop(
                  context,
                  FitnessProfile(
                    isConfigured: true,
                    gender: _gender,
                    dateOfBirth: _dobCtrl.text.trim(),
                    heightCm: double.tryParse(_heightCtrl.text),
                    currentWeightKg: double.tryParse(_weightCtrl.text),
                    targetWeightKg: double.tryParse(_targetCtrl.text),
                    fitnessGoal: _goal,
                    activityLevel: _activity,
                    fitnessExperienceLevel: _experience,
                    workoutLocationPreference: _location,
                    injuries: cleanInjuries,
                    medications: widget.initial.medications,
                    baseTdee: widget.initial.baseTdee,
                    bmr: widget.initial.bmr,
                    dailyProteinTargetGram: widget.initial.dailyProteinTargetGram,
                    dailyCarbTargetGram: widget.initial.dailyCarbTargetGram,
                    dailyFatTargetGram: widget.initial.dailyFatTargetGram,
                  ),
                );
              },
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
          ],
        ),
      ),
    );
  }
}

Future<AccountPreferences?> showPreferencesEditor(
  BuildContext context,
  AccountPreferences prefs,
) async {
  return showModalBottomSheet<AccountPreferences>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PreferencesEditorSheet(initial: prefs),
  );
}

class _PreferencesEditorSheet extends StatefulWidget {
  const _PreferencesEditorSheet({required this.initial});

  final AccountPreferences initial;

  @override
  State<_PreferencesEditorSheet> createState() => _PreferencesEditorSheetState();
}

class _PreferencesEditorSheetState extends State<_PreferencesEditorSheet> {
  late List<String> _allergies;
  late List<String> _favorites;
  late List<String> _disliked;
  late String _persona;
  late String _motivation;
  late bool _dataConsent;
  late bool _marketingConsent;

  @override
  void initState() {
    super.initState();
    _allergies = widget.initial.allergies.map((e) => e.allergenName).toList();
    _favorites = List<String>.from(widget.initial.favoriteFoods);
    _disliked = List<String>.from(widget.initial.dislikedFoods);
    _persona = widget.initial.agentPersona.isNotEmpty ? widget.initial.agentPersona : 'FriendlyBuddy';
    _motivation = widget.initial.motivationStyle.isNotEmpty ? widget.initial.motivationStyle : 'Supportive';
    _dataConsent = widget.initial.dataSharingConsent;
    _marketingConsent = widget.initial.marketingConsent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.preferencesEditorTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            SearchableTagField(
              label: l10n.favoriteFoodsLabel,
              hint: l10n.favoriteFoodsSearchHint,
              catalog: OnboardingTagCatalog.favoriteFoods,
              popularTags: OnboardingTagCatalog.favoriteFoodsPopular,
              selected: _favorites,
              onChanged: (v) => setState(() => _favorites = v),
            ),
            const SizedBox(height: 16),
            SearchableTagField(
              label: l10n.dislikedFoodsLabel,
              hint: l10n.dislikedFoodsSearchHint,
              catalog: OnboardingTagCatalog.dislikedFoods,
              popularTags: OnboardingTagCatalog.dislikedFoodsPopular,
              selected: _disliked,
              onChanged: (v) => setState(() => _disliked = v),
            ),
            const SizedBox(height: 12),
            _enumDropdown(l10n.aiCoachStyleLabel, _persona, L10nEnums.personaOptions(l10n), (v) {
              setState(() => _persona = v);
            }),
            const SizedBox(height: 12),
            _enumDropdown(l10n.motivationStyleLabel, _motivation, L10nEnums.motivationOptions(l10n), (v) {
              setState(() => _motivation = v);
            }),
            CheckboxListTile(
              value: _dataConsent,
              onChanged: (v) => setState(() => _dataConsent = v ?? false),
              title: Text(l10n.consentDataSharing, style: const TextStyle(fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _marketingConsent,
              onChanged: (v) => setState(() => _marketingConsent = v ?? false),
              title: Text(l10n.consentMarketing, style: const TextStyle(fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: l10n.actionSave,
              onPressed: () {
                Navigator.pop(
                  context,
                  widget.initial.copyWith(
                    allergies: _allergies.map((n) => AllergyItem(allergenName: n)).toList(),
                    favoriteFoods: _favorites,
                    dislikedFoods: _disliked,
                    agentPersona: _persona,
                    motivationStyle: _motivation,
                    dataSharingConsent: _dataConsent,
                    marketingConsent: _marketingConsent,
                  ),
                );
              },
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
          ],
        ),
      ),
    );
  }
}

Future<double?> showLogWeightSheet(BuildContext context, {double? current}) async {
  final l10n = context.l10n;
  final ctrl = TextEditingController(text: current?.toStringAsFixed(1) ?? '');

  final saved = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.logWeightTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          CustomTextField(label: l10n.currentWeightKgLabel, controller: ctrl, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          PrimaryButton(label: l10n.logWeightSave, onPressed: () => Navigator.pop(ctx, true)),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
        ],
      ),
    ),
  );

  final value = double.tryParse(ctrl.text);
  ctrl.dispose();
  if (saved != true || value == null) return null;
  return value;
}

Widget _enumDropdown(
  String label,
  String value,
  Map<String, String> options,
  ValueChanged<String> onChanged,
) {
  final keys = options.keys.toList();
  final safeValue = keys.contains(value) ? value : keys.first;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: safeValue,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.background,
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
