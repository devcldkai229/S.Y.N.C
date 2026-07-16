import 'package:sync_app/features/workouts/data/ai_roadmap_repository.dart';
import 'package:sync_app/features/workouts/models/roadmap_overview_models.dart';

/// Static mock for AI Roadmap redesign / offline preview.
class MockAiRoadmapRepository implements AiRoadmapRepository {
  const MockAiRoadmapRepository();

  @override
  Future<RoadmapOverview?> loadOverview() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));

    return RoadmapOverview(
      roadmapId: 'mock-roadmap-1',
      roadmapName: 'Lộ trình Giảm mỡ 12 tuần',
      fitnessGoal: 'FatLoss',
      currentWeek: 5,
      totalWeeks: 12,
      phases: const [
        RoadmapPhaseOverview(
          key: 'foundation',
          displayNameVi: 'Nền tảng',
          displayNameEn: 'Foundation',
          status: 'Done',
          weekFrom: 1,
          weekTo: 4,
        ),
        RoadmapPhaseOverview(
          key: 'build',
          displayNameVi: 'Tăng cường',
          displayNameEn: 'Build',
          status: 'Current',
          weekFrom: 5,
          weekTo: 8,
        ),
        RoadmapPhaseOverview(
          key: 'peak',
          displayNameVi: 'Bứt phá',
          displayNameEn: 'Peak',
          status: 'Upcoming',
          weekFrom: 9,
          weekTo: 12,
        ),
      ],
      phaseRationaleVi:
          'Giai đoạn tăng cường kết hợp sức mạnh và cardio để đẩy tốc độ giảm mỡ, vẫn giữ kỹ thuật ổn định.',
      phaseRationaleEn:
          'Build phase combines strength and cardio to accelerate fat loss while keeping technique solid.',
      progress: const RoadmapProgressOverview(
        phasePercent: 25,
        currentWeightKg: 75.5,
        targetWeightKg: 72,
      ),
      readiness: const RoadmapReadinessOverview(
        level: 'Ready',
        score: 72,
        fatigue: 48,
        soreness: 28,
        aiAdjustmentNoteVi: 'AI giữ nguyên kế hoạch hôm nay vì bạn đủ khoẻ.',
        aiAdjustmentNoteEn: 'AI keeps today\'s plan as-is because you are ready enough.',
      ),
      sessions: [
        RoadmapSessionOverview(
          id: 'mock-session-done',
          displayNameVi: 'Đẩy thân trên',
          subtitleEn: 'Push Upper',
          status: 'Completed',
          durationMin: 45,
          exerciseCount: 2,
          scheduledTime: '07:00',
          scheduledDate: monday,
          intensity: 'Moderate',
          isAi: true,
          rationaleVi: 'Buổi sức mạnh kích thích nhóm cơ lớn, giúp đốt mỡ hiệu quả hơn ở giai đoạn này.',
          rationaleEn: 'Strength work hits large muscle groups to burn fat more effectively in this phase.',
        ),
        RoadmapSessionOverview(
          id: 'mock-session-next',
          displayNameVi: 'Sức mạnh thân dưới',
          subtitleEn: 'Lower Strength',
          status: 'Scheduled',
          durationMin: 50,
          exerciseCount: 3,
          scheduledTime: '07:00',
          scheduledDate: monday.add(const Duration(days: 2)),
          intensity: 'High',
          isAi: true,
          rationaleVi: 'Buổi chân kích thích nhóm cơ lớn, giúp đốt mỡ hiệu quả hơn ở giai đoạn này.',
          rationaleEn: 'Lower-body work hits large muscle groups for fat loss in this phase.',
          isNextUp: true,
        ),
        RoadmapSessionOverview(
          id: 'mock-session-cardio',
          displayNameVi: 'Cardio nhẹ',
          subtitleEn: 'Cardio',
          status: 'Scheduled',
          durationMin: 35,
          exerciseCount: 2,
          scheduledTime: '18:30',
          scheduledDate: monday.add(const Duration(days: 4)),
          intensity: 'Light',
          isAi: true,
          rationaleVi: 'Cardio hỗ trợ thâm hụt calo và sức bền tim mạch trong giai đoạn giảm mỡ.',
          rationaleEn: 'Cardio supports a calorie deficit and cardiovascular endurance during fat loss.',
        ),
      ],
    );
  }
}
