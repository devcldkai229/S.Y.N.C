using Libs.Shared.Enums;
using Roadmap.Application.DTOs;
using Roadmap.Application.Helpers;
using Roadmap.Domain.Repositories;

namespace Roadmap.Application.Services;

public class RoadmapOverviewService : IRoadmapOverviewService
{
    private readonly IPersonalizedRoadmapService _roadmaps;
    private readonly IRoadmapSessionRepository _sessions;
    private readonly IRecoveryProfileService _recovery;

    public RoadmapOverviewService(
        IPersonalizedRoadmapService roadmaps,
        IRoadmapSessionRepository sessions,
        IRecoveryProfileService recovery)
    {
        _roadmaps = roadmaps;
        _sessions = sessions;
        _recovery = recovery;
    }

    public async Task<RoadmapOverviewDto?> GetMyOverviewAsync(
        Guid userId,
        string? experienceLevel = null,
        CancellationToken cancellationToken = default)
    {
        var roadmap = await _roadmaps.GetActiveByUserIdAsync(userId, cancellationToken);
        if (roadmap is null)
            return null;

        var now = DateTimeOffset.UtcNow;
        var totalWeeks = RoadmapPhaseCatalog.ComputeTotalWeeks(roadmap.StartDate, roadmap.ExpectedEndDate);
        var currentWeek = RoadmapPhaseCatalog.ComputeCurrentWeek(roadmap.StartDate, roadmap.ExpectedEndDate, now);
        var phases = RoadmapPhaseCatalog.BuildPhases(roadmap.CurrentPhase, totalWeeks);
        var currentPhaseKey = RoadmapPhaseCatalog.ResolveCurrentPhaseKey(roadmap.CurrentPhase);
        var goal = RoadmapPhaseCatalog.NormalizeGoal(roadmap.FitnessGoal);
        var experience = RoadmapPhaseCatalog.NormalizeExperience(experienceLevel);
        var (phaseVi, phaseEn) = RoadmapRationaleTemplates.PhaseRationale(goal, experience, currentPhaseKey);

        var weekStart = StartOfWeek(now);
        var weekEnd = weekStart.AddDays(7);
        var weekSessions = await _sessions.GetByRoadmapIdAndDateRangeAsync(
            roadmap.Id,
            weekStart,
            weekEnd,
            cancellationToken);

        var ordered = weekSessions
            .OrderBy(s => s.ScheduledDate)
            .ThenBy(s => s.ScheduledTime)
            .ToList();

        var nextId = ordered
            .FirstOrDefault(s =>
                s.SessionStatus is SessionStatus.Scheduled or SessionStatus.InProgress &&
                s.ScheduledDate.Date >= now.Date)
            ?.Id
            ?? ordered.FirstOrDefault(s => s.SessionStatus is SessionStatus.Scheduled or SessionStatus.InProgress)?.Id;

        var sessionDtos = ordered.Select(s =>
        {
            var intensity = SessionDisplayNameMapper.IntensityFromEnergy(s.EnergyDemandScore);
            var (rVi, rEn) = RoadmapRationaleTemplates.SessionRationale(
                s.SessionType,
                goal,
                s.EnergyDemandScore,
                s.RecoveryRequirementScore);

            return new SessionOverviewDto
            {
                Id = s.Id,
                DisplayNameVi = SessionDisplayNameMapper.ToDisplayNameVi(s.SessionTitle, s.SessionType),
                SubtitleEn = string.IsNullOrWhiteSpace(s.SessionTitle) ? s.SessionType : s.SessionTitle,
                Status = s.SessionStatus.ToString(),
                DurationMin = s.EstimatedDurationMinutes,
                ExerciseCount = s.ExecutionBlocks?.Count ?? 0,
                ScheduledTime = string.IsNullOrWhiteSpace(s.ScheduledTime) ? null : s.ScheduledTime,
                ScheduledDate = s.ScheduledDate,
                Intensity = intensity,
                IsAi = s.AiGenerated,
                RationaleVi = rVi,
                RationaleEn = rEn,
                IsNextUp = nextId.HasValue && s.Id == nextId.Value,
            };
        }).ToList();

        ReadinessOverviewDto? readiness = null;
        var (recoveryItems, _) = await _recovery.GetPagedAsync(1, 1, userId, cancellationToken);
        var recovery = recoveryItems.FirstOrDefault();
        if (recovery is not null)
        {
            var level = RoadmapRationaleTemplates.ReadinessLevel(recovery.CurrentRecoveryScore);
            var (noteVi, noteEn) = RoadmapRationaleTemplates.AiAdjustmentNote(
                roadmap.AllowAiIntensityAdjustment,
                level);

            readiness = new ReadinessOverviewDto
            {
                Level = level,
                Score = recovery.CurrentRecoveryScore,
                Fatigue = recovery.FatigueLevel,
                Soreness = recovery.MuscleSorenessScore,
                AiAdjustmentNoteVi = noteVi,
                AiAdjustmentNoteEn = noteEn,
            };
        }

        decimal? currentWeight = roadmap.CurrentWeightKg > 0 ? roadmap.CurrentWeightKg : null;
        decimal? targetWeight = roadmap.TargetWeightKg > 0 ? roadmap.TargetWeightKg : null;

        return new RoadmapOverviewDto
        {
            RoadmapId = roadmap.Id,
            RoadmapName = roadmap.RoadmapName,
            FitnessGoal = roadmap.FitnessGoal,
            CurrentWeek = currentWeek,
            TotalWeeks = totalWeeks,
            Phases = phases,
            PhaseRationaleVi = phaseVi,
            PhaseRationaleEn = phaseEn,
            Progress = new ProgressOverviewDto
            {
                PhasePercent = RoadmapPhaseCatalog.PhasePercent(phases, currentWeek),
                CurrentWeightKg = currentWeight,
                TargetWeightKg = targetWeight,
            },
            Readiness = readiness,
            Sessions = sessionDtos,
        };
    }

    private static DateTimeOffset StartOfWeek(DateTimeOffset now)
    {
        // Monday-start week in UTC for consistency with server-side scheduling.
        var date = now.UtcDateTime.Date;
        var diff = ((int)date.DayOfWeek + 6) % 7; // Monday = 0
        return new DateTimeOffset(date.AddDays(-diff), TimeSpan.Zero);
    }
}
