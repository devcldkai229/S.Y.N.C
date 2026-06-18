import 'package:flutter/material.dart';

/// Hardcoded UI models and seed data for the Achievements screen.
class UserStatsDisplay {
  const UserStatsDisplay({
    required this.level,
    required this.xp,
    required this.streakDays,
    required this.coins,
    required this.points,
  });

  final int level;
  final int xp;
  final int streakDays;
  final int coins;
  final int points;

  static const demo = UserStatsDisplay(
    level: 5,
    xp: 1600,
    streakDays: 7,
    coins: 510,
    points: 485,
  );
}

class InProgressAchievement {
  const InProgressAchievement({
    required this.title,
    required this.description,
    required this.current,
    required this.required,
    required this.percent,
    required this.icon,
  });

  final String title;
  final String description;
  final int current;
  final int required;
  final int percent;
  final IconData icon;
}

class UnlockedAchievement {
  const UnlockedAchievement({
    required this.title,
    required this.description,
    required this.xpReward,
    required this.coinReward,
  });

  final String title;
  final String description;
  final int xpReward;
  final int coinReward;
}

abstract final class AchievementDisplayData {
  static const inProgress = [
    InProgressAchievement(
      title: 'Dedicated Athlete',
      description: 'Complete 10 workouts this month',
      current: 5,
      required: 10,
      percent: 50,
      icon: Icons.fitness_center_outlined,
    ),
    InProgressAchievement(
      title: 'Perfect Week',
      description: 'Hit 100% daily goals for 7 days',
      current: 3,
      required: 7,
      percent: 43,
      icon: Icons.calendar_today_outlined,
    ),
    InProgressAchievement(
      title: 'Chuỗi 30 ngày',
      description: 'Duy trì streak tập luyện 30 ngày liên tiếp',
      current: 7,
      required: 30,
      percent: 23,
      icon: Icons.local_fire_department_outlined,
    ),
    InProgressAchievement(
      title: 'Elite Athlete',
      description: 'Đạt cấp độ 25 trên SYNC',
      current: 5,
      required: 25,
      percent: 20,
      icon: Icons.military_tech_outlined,
    ),
  ];

  static const unlocked = [
    UnlockedAchievement(
      title: 'Chuỗi 7 ngày',
      description: 'Duy trì streak tập luyện 7 ngày liên tiếp',
      xpReward: 200,
      coinReward: 50,
    ),
    UnlockedAchievement(
      title: 'Rising Star',
      description: 'Hoàn thành 5 buổi tập đầu tiên',
      xpReward: 0,
      coinReward: 100,
    ),
    UnlockedAchievement(
      title: 'Triple Threat',
      description: 'Hoàn thành 100% mục tiêu cả ăn lẫn tập 3 ngày liên tiếp',
      xpReward: 150,
      coinReward: 40,
    ),
  ];
}
