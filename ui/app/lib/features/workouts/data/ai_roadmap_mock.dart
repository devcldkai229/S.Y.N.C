import 'package:sync_app/features/workouts/data/ai_roadmap_repository.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

/// Static mock data for AI Roadmap redesign — swap implementation for API later.
class MockAiRoadmapRepository implements AiRoadmapRepository {
  const MockAiRoadmapRepository();

  @override
  Future<AiRoadmapSnapshot> loadSnapshot() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));

    final roadmap = PersonalizedRoadmap(
      id: 'mock-roadmap-1',
      roadmapName: 'Lộ trình Giảm mỡ 12 tuần',
      fitnessGoal: 'FatLoss',
      currentPhase: 'Foundation',
      startDate: monday.subtract(const Duration(days: 28)),
      expectedEndDate: monday.add(const Duration(days: 56)),
      roadmapStatus: 'Active',
      currentWeightKg: 78.0,
      targetWeightKg: 72.0,
      adaptiveAiEnabled: true,
    );

    final recovery = RecoveryProfile(
      fatigueLevel: 48,
      muscleSorenessScore: 28,
      currentRecoveryScore: 72,
      recommendedTrainingIntensity: 'Moderate',
    );

    final sessions = [
      AiRoadmapSessionEntry(
        session: RoadmapSession(
          id: 'mock-session-done',
          roadmapId: roadmap.id,
          scheduledDate: monday,
          sessionTitle: 'Push Upper',
          sessionType: 'Strength',
          estimatedDurationMinutes: 45,
          sessionStatus: 'Completed',
          aiGenerated: true,
          scheduledTime: '07:00',
          exerciseCount: 2,
        ),
        energyDemandScore: 55,
      ),
      AiRoadmapSessionEntry(
        session: RoadmapSession(
          id: 'mock-session-next',
          roadmapId: roadmap.id,
          scheduledDate: monday.add(const Duration(days: 2)),
          sessionTitle: 'Lower Strength',
          sessionType: 'Strength',
          estimatedDurationMinutes: 50,
          sessionStatus: 'Scheduled',
          aiGenerated: true,
          scheduledTime: '07:00',
          exerciseCount: 3,
        ),
        energyDemandScore: 68,
        isNextUp: true,
      ),
      AiRoadmapSessionEntry(
        session: RoadmapSession(
          id: 'mock-session-cardio',
          roadmapId: roadmap.id,
          scheduledDate: monday.add(const Duration(days: 4)),
          sessionTitle: 'Cardio nhẹ',
          sessionType: 'Cardio',
          estimatedDurationMinutes: 35,
          sessionStatus: 'Scheduled',
          aiGenerated: true,
          scheduledTime: '18:30',
          exerciseCount: 2,
        ),
        energyDemandScore: 38,
      ),
      AiRoadmapSessionEntry(
        session: RoadmapSession(
          id: 'mock-session-recovery',
          roadmapId: roadmap.id,
          scheduledDate: monday.add(const Duration(days: 5)),
          sessionTitle: 'Mobility & phục hồi',
          sessionType: 'Recovery',
          estimatedDurationMinutes: 30,
          sessionStatus: 'Scheduled',
          aiGenerated: true,
          scheduledTime: '09:00',
          exerciseCount: 2,
        ),
        energyDemandScore: 22,
      ),
    ];

    return AiRoadmapSnapshot(
      roadmap: roadmap,
      recovery: recovery,
      weekSessions: sessions,
      progressPercent: 50,
      currentWeek: 5,
      totalWeeks: 12,
      cnsFatigueScore: 42,
    );
  }
}
