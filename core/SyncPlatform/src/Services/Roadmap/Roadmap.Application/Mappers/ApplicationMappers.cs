using Roadmap.Application.DTOs;
using Roadmap.Domain.Models;

namespace Roadmap.Application.Mappers;

public static class ApplicationMappers
{
    // ── UserCustomWorkout ────────────────────────────────────────────────────

    public static UserCustomWorkoutDto ToDto(this UserCustomWorkout entity)
    {
        return new UserCustomWorkoutDto
        {
            Id = entity.Id,
            UserId = entity.UserId,
            WorkoutName = entity.WorkoutName,
            Visibility = entity.Visibility,
            ScheduleMode = entity.ScheduleMode,
            AllowAiOptimization = entity.AllowAiOptimization,
            CreatedAt = entity.CreatedAt,
            CustomBlocks = entity.CustomBlocks.Select(b => new CustomBlockDto
            {
                ExerciseId = b.ExerciseId,
                Sets = b.Sets,
                Reps = b.Reps,
                WeightKg = b.WeightKg,
                RestSeconds = b.RestSeconds
            }).ToList()
        };
    }

    public static void UpdateEntity(this UserCustomWorkout entity, CreateUserCustomWorkoutDto dto)
    {
        entity.UserId = dto.UserId;
        entity.WorkoutName = dto.WorkoutName;
        entity.ScheduleMode = dto.ScheduleMode;
        entity.Visibility = dto.Visibility;
        entity.AllowAiOptimization = dto.AllowAiOptimization;
        entity.CustomBlocks = dto.CustomBlocks.Select(b => new UserCustomWorkout.CustomBlock
        {
            ExerciseId = b.ExerciseId,
            Sets = b.Sets,
            Reps = b.Reps,
            WeightKg = b.WeightKg,
            RestSeconds = b.RestSeconds
        }).ToList();
    }

    // ── RoadmapSession ───────────────────────────────────────────────────────

    public static RoadmapSessionDto ToDto(this RoadmapSession entity)
    {
        return new RoadmapSessionDto
        {
            Id = entity.Id,
            RoadmapId = entity.RoadmapId,
            ScheduledDate = entity.ScheduledDate,
            ScheduledTime = entity.ScheduledTime,
            Timezone = entity.Timezone,
            SessionType = entity.SessionType,
            SessionTitle = entity.SessionTitle,
            EstimatedDurationMinutes = entity.EstimatedDurationMinutes,
            NotificationEnabled = entity.NotificationEnabled,
            NotificationMinutesBefore = entity.NotificationMinutesBefore,
            AiGenerated = entity.AiGenerated,
            SessionStatus = entity.SessionStatus,
            CreatedAt = entity.CreatedAt,
            ExecutionBlocks = entity.ExecutionBlocks.Select(b => new ExecutionBlockDto
            {
                Order = b.Order,
                ExerciseId = b.ExerciseId,
                ExerciseName = b.ExerciseName,
                ExerciseAssetId = b.ExerciseAssetId,
                TargetSets = b.TargetSets,
                TargetReps = b.TargetReps,
                TargetWeightKg = b.TargetWeightKg,
                RestSeconds = b.RestSeconds,
                Tempo = b.Tempo,
                ExerciseNotes = b.ExerciseNotes
            }).ToList()
        };
    }

    public static void UpdateEntity(this RoadmapSession entity, ScheduleSessionDto dto)
    {
        // null RoadmapId = "Free Workout" — no roadmap context
        entity.RoadmapId = dto.RoadmapId ?? Guid.Empty;
        entity.ScheduledDate = dto.ScheduledDate;
        entity.ScheduledTime = dto.ScheduledTime;
        entity.Timezone = dto.Timezone;
        entity.SessionTitle = dto.SessionTitle;
        entity.SessionType = dto.SessionType;
        entity.EstimatedDurationMinutes = dto.EstimatedDurationMinutes;
        entity.NotificationEnabled = dto.NotificationEnabled;
        entity.NotificationMinutesBefore = dto.NotificationMinutesBefore;
        entity.AiGenerated = false;
        entity.ExecutionBlocks = dto.ExecutionBlocks.Select(b => new RoadmapSession.ExecutionBlock
        {
            Order = b.Order,
            ExerciseId = b.ExerciseId,
            ExerciseName = b.ExerciseName,
            ExerciseAssetId = b.ExerciseAssetId,
            TargetSets = b.TargetSets,
            TargetReps = b.TargetReps,
            TargetWeightKg = b.TargetWeightKg,
            RestSeconds = b.RestSeconds,
            Tempo = b.Tempo,
            ExerciseNotes = b.ExerciseNotes
        }).ToList();
    }

    // ── WorkoutExecutionLog ──────────────────────────────────────────────────

    public static ExerciseSetLogDto ToDto(this ExerciseSetLog entity)
    {
        return new ExerciseSetLogDto
        {
            Id = entity.Id,
            ExecutionId = entity.ExecutionId,
            ExerciseId = entity.ExerciseId,
            SetNumber = entity.SetNumber,
            TargetReps = entity.TargetReps,
            ActualReps = entity.ActualReps,
            WeightKg = entity.WeightKg,
            Rir = entity.Rir,
            RestTakenSeconds = entity.RestTakenSeconds,
            FormScore = entity.FormScore,
            Completed = entity.Completed
        };
    }

    public static WorkoutExecutionResultDto ToResultDto(
        this WorkoutExecutionLog log,
        IReadOnlyList<ExerciseSetLog> sets)
    {
        return new WorkoutExecutionResultDto
        {
            ExecutionLogId = log.Id,
            SessionId = log.SessionId,
            UserId = log.UserId,
            StartedAt = log.StartedAt,
            CompletedAt = log.CompletedAt,
            ActualDurationMinutes = log.ActualDurationMinutes,
            PerceivedDifficulty = log.PerceivedDifficulty,
            EnergyLevelBefore = log.EnergyLevelBefore,
            EnergyLevelAfter = log.EnergyLevelAfter,
            CaloriesBurned = log.CaloriesBurned,
            CompletionRate = log.CompletionRate,
            SkippedExercises = log.SkippedExercises,
            SetsPerformed = sets.Select(s => s.ToDto()).ToList()
        };
    }

    // ── ScheduledWorkout ─────────────────────────────────────────────────────

    public static ScheduledWorkoutDto ToDto(this ScheduledWorkout entity)
    {
        return new ScheduledWorkoutDto
        {
            Id = entity.Id,
            UserId = entity.UserId,
            SessionId = entity.SessionId,
            ScheduledStartTime = entity.ScheduledStartTime,
            ScheduledEndTime = entity.ScheduledEndTime,
            Status = entity.Status,
            RepeatPattern = entity.RepeatPattern
        };
    }
}
