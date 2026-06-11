import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/achievements/cubit/achievements_cubit.dart';
import 'package:sync_app/features/achievements/widgets/achievements_theme.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

class LogActivityButton extends StatefulWidget {
  const LogActivityButton({super.key});

  @override
  State<LogActivityButton> createState() => _LogActivityButtonState();
}

class _LogActivityButtonState extends State<LogActivityButton> {
  bool _loading = false;

  Future<void> _log() async {
    setState(() => _loading = true);
    try {
      final result = await getIt<ProfileApiService>().logActivity();
      if (!mounted) return;

      if (result.alreadyLoggedToday) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hôm nay bạn đã ghi nhận rồi. Streak: ${result.currentStreak} ngày'),
            backgroundColor: AchievementsTheme.slate,
          ),
        );
      } else {
        final unlocked = result.newlyUnlockedAchievements;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              unlocked.isEmpty
                  ? 'Đã ghi nhận! Streak: ${result.currentStreak} ngày'
                  : 'Streak: ${result.currentStreak} ngày — Mở khóa: ${unlocked.join(', ')}',
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        if (mounted) context.read<AchievementsCubit>().load();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _log,
          style: ElevatedButton.styleFrom(
            backgroundColor: AchievementsTheme.slate,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          icon: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.local_fire_department_outlined, size: 20),
          label: Text(
            _loading ? 'Đang ghi nhận...' : 'Ghi nhận hoạt động hôm nay',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
