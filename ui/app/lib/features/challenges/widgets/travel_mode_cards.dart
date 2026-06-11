import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/challenges/models/challenge_models.dart';
import 'package:sync_app/features/challenges/models/challenge_route_models.dart';

class TravelModeCards extends StatelessWidget {
  const TravelModeCards({
    super.key,
    required this.selected,
    required this.onSelected,
    this.route,
    this.loading = false,
  });

  final TravelMode selected;
  final ValueChanged<TravelMode> onSelected;
  final ChallengeRoute? route;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TravelMode.values.map((mode) {
        final info = route?.forMode(mode);
        final isSelected = selected == mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: mode != TravelMode.walking ? 8 : 0),
            child: GestureDetector(
              onTap: loading ? null : () => onSelected(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.lightGreen : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text('${mode.emoji} ${mode.label}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      Text(
                        info?.durationLabel ?? '—',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      if (info != null && info.arrivalLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          info.arrivalLabel,
                          style: const TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        info?.distanceLabel ?? '—',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
