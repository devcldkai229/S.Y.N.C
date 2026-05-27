import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/models/onboarding_models.dart';
import 'package:sync_app/features/onboarding/cubit/onboarding_cubit.dart';
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

  final _dobController = TextEditingController(text: '1995-01-01');
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '70');
  final _targetWeightController = TextEditingController(text: '68');
  final _bodyFatController = TextEditingController();
  final _goalFatController = TextEditingController();

  String _gender = 'Male';
  String _fitnessGoal = 'Hypertrophy';
  String _activityLevel = 'Moderate';
  String _experience = 'Intermediate';
  String _location = 'Gym';

  @override
  void dispose() {
    _pageController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _bodyFatController.dispose();
    _goalFatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(getIt()),
      child: BlocListener<OnboardingCubit, OnboardingState>(
        listenWhen: (p, c) => p.isCompleted != c.isCompleted,
        listener: (context, state) {
          if (state.isCompleted) context.go(AppRoutes.home);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                ProgressHeader(
                  currentStep: _page + 1,
                  totalSteps: 4,
                  onClose: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.home);
                    }
                  },
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _stepBasic(),
                      _stepGoals(),
                      _stepComposition(),
                      _stepSafeguards(),
                    ],
                  ),
                ),
                BlocBuilder<OnboardingCubit, OnboardingState>(
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        children: [
                          if (state.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                state.error!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          PrimaryButton(
                            label: _page < 3 ? 'Continue' : 'Finish Setup',
                            isLoading: state.isSubmitting,
                            onPressed: state.isSubmitting ? () {} : () => _onContinue(context),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => context.go(AppRoutes.home),
                            child: const Text('Skip for now'),
                          ),
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

  Widget _stepBasic() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About you', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Gender, birthday, and height help calibrate your plan.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _dropdown('Gender', _gender, ['Male', 'Female', 'Other'], (v) => setState(() => _gender = v)),
          const SizedBox(height: 16),
          CustomTextField(label: 'Date of birth (YYYY-MM-DD)', controller: _dobController),
          const SizedBox(height: 16),
          CustomTextField(label: 'Height (cm)', controller: _heightController, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _stepGoals() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your goals', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          CustomTextField(label: 'Current weight (kg)', controller: _weightController, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          CustomTextField(label: 'Target weight (kg)', controller: _targetWeightController, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _dropdown('Fitness goal', _fitnessGoal,
              ['Hypertrophy', 'FatLoss', 'Endurance', 'Strength', 'GeneralFitness'], (v) => setState(() => _fitnessGoal = v)),
          const SizedBox(height: 16),
          _dropdown('Activity level', _activityLevel,
              ['Sedentary', 'Light', 'Moderate', 'Active', 'VeryActive'], (v) => setState(() => _activityLevel = v)),
          const SizedBox(height: 16),
          _dropdown('Experience', _experience,
              ['Beginner', 'Intermediate', 'Advanced'], (v) => setState(() => _experience = v)),
          const SizedBox(height: 16),
          _dropdown('Training location', _location, ['Gym', 'Home', 'Outdoor', 'Hybrid'],
              (v) => setState(() => _location = v)),
        ],
      ),
    );
  }

  Widget _stepComposition() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Body composition', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Optional — skip fields you do not know yet.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          CustomTextField(label: 'Current body fat %', controller: _bodyFatController, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          CustomTextField(label: 'Goal body fat %', controller: _goalFatController, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _stepSafeguards() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Safety', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text(
            'Tell your AI coach about injuries or medications so workouts stay safe.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
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
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Future<void> _onContinue(BuildContext context) async {
    final cubit = context.read<OnboardingCubit>();
    final bool ok;
    if (_page == 0) {
      ok = await cubit.submitStep1(OnboardingStep1Request(
        gender: _gender,
        dateOfBirth: _dobController.text.trim(),
        heightCm: double.tryParse(_heightController.text) ?? 170,
      ));
    } else if (_page == 1) {
      ok = await cubit.submitStep2(OnboardingStep2Request(
        currentWeightKg: double.tryParse(_weightController.text) ?? 70,
        targetWeightKg: double.tryParse(_targetWeightController.text) ?? 68,
        fitnessGoal: _fitnessGoal,
        activityLevel: _activityLevel,
        fitnessExperienceLevel: _experience,
        workoutLocationPreference: _location,
      ));
    } else if (_page == 2) {
      ok = await cubit.submitStep3(OnboardingStep3Request(
        currentBodyFatPercentage: double.tryParse(_bodyFatController.text),
        goalBodyFatPercentage: double.tryParse(_goalFatController.text),
      ));
    } else {
      ok = await cubit.submitStep4(OnboardingStep4Request());
    }
    if (!ok || !mounted) return;
    if (_page < 3) {
      setState(() => _page++);
      await _pageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }
}
