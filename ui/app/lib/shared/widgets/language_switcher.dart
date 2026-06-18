import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/locale/locale_cubit.dart';
import 'package:sync_app/core/theme/app_colors.dart';

/// Segmented control for Vietnamese / English — syncs [LocaleCubit] + IAM profile.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = context.watch<LocaleCubit>().currentCode;

    final control = SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'vi', label: Text(compact ? 'VI' : l10n.languageVietnamese)),
        ButtonSegment(value: 'en', label: Text(compact ? 'EN' : l10n.languageEnglish)),
      ],
      selected: {code},
      onSelectionChanged: (selected) {
        final next = selected.first;
        context.read<LocaleCubit>().changeLanguage(next);
      },
      style: ButtonStyle(
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      ),
    );

    if (compact) return control;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.languageTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        control,
      ],
    );
  }
}

/// Compact language toggle for app bars.
class LanguageIconToggle extends StatelessWidget {
  const LanguageIconToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final code = context.watch<LocaleCubit>().currentCode;
    final next = code == 'vi' ? 'en' : 'vi';

    return IconButton(
      tooltip: code == 'vi' ? 'English' : 'Tiếng Việt',
      onPressed: () => context.read<LocaleCubit>().changeLanguage(next),
      icon: Text(
        code.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }
}
