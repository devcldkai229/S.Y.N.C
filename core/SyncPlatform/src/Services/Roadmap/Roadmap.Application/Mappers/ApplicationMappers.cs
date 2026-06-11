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
            ParentWorkoutId = entity.ParentWorkoutId,
            SavesCount = entity.SavesCount,
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
            WeightKg = (double)entity.WeightKg,
            Rir = entity.Rir,
            RestTakenSeconds = entity.RestTakenSeconds,
            FormScore = entity.FormScore,
            Completed = entity.Completed
        };
    }

    public static WorkoutExecutionDetailDto ToDetailDto(
        this WorkoutExecutionLog log,
        RoadmapSession session,
        IReadOnlyList<ExerciseSetLog> setLogs)
    {
        return new WorkoutExecutionDetailDto
        {
            ExecutionId = log.Id,
            SessionId = log.SessionId,
            SessionTitle = session.SessionTitle,
            StartedAt = log.StartedAt,
            EnergyLevelBefore = log.EnergyLevelBefore,
            Exercises = session.ExecutionBlocks
                .OrderBy(b => b.Order)
                .GroupBy(b => b.ExerciseId)
                .Select(g =>
                {
                    var firstBlock = g.First();
                    return new ExecutionExerciseDto
                    {
                        ExerciseId = g.Key,
                        ExerciseName = firstBlock.ExerciseName,
                        ExerciseAssetId = firstBlock.ExerciseAssetId,
                        Order = firstBlock.Order,
                        Sets = setLogs
                            .Where(s => s.ExerciseId == g.Key)
                            .OrderBy(s => s.SetNumber)
                            .Select(s => s.ToDto())
                            .ToList()
                    };
                })
                .OrderBy(e => e.Order)
                .ToList()
        };
    }

    public static WorkoutExecutionSummaryDto ToSummaryDto(
        this WorkoutExecutionLog log,
        string sessionTitle,
        int completedSetCount,
        int totalSetCount)
    {
        return new WorkoutExecutionSummaryDto
        {
            ExecutionId = log.Id,
            SessionId = log.SessionId,
            SessionTitle = sessionTitle,
            StartedAt = log.StartedAt,
            CompletedAt = log.CompletedAt ?? DateTimeOffset.UtcNow,
            ActualDurationMinutes = log.ActualDurationMinutes,
            CompletionRate = log.CompletionRate,
            CompletedSetCount = completedSetCount,
            TotalSetCount = totalSetCount,
            SkippedExerciseCount = log.SkippedExercises.Count,
            PerceivedDifficulty = log.PerceivedDifficulty,
            EnergyLevelBefore = log.EnergyLevelBefore,
            EnergyLevelAfter = log.EnergyLevelAfter,
            CaloriesBurned = log.CaloriesBurned,
            AiCoachFeedback = log.AiCoachFeedback ?? string.Empty,
            SessionFeedback = log.SessionFeedback
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

    // ── ExerciseSetLog Extensions ────────────────────────────────────────────

    public static ExerciseSetLog ToEntity(this CreateExerciseSetLogDto dto)
    {
        return new ExerciseSetLog
        {
            ExecutionId = dto.ExecutionId,
            ExerciseId = dto.ExerciseId,
            SetNumber = dto.SetNumber,
            TargetReps = dto.TargetReps,
            ActualReps = dto.ActualReps,
            WeightKg = dto.WeightKg,
            Rir = dto.Rir,
            RestTakenSeconds = dto.RestTakenSeconds,
            FormScore = dto.FormScore,
            Completed = dto.Completed
        };
    }

    // ── PersonalizedRoadmap Extensions ───────────────────────────────────────

    public static PersonalizedRoadmapDto ToDto(this PersonalizedRoadmap entity)
    {
        return new PersonalizedRoadmapDto
        {
            Id = entity.Id,
            UserId = entity.UserId,
            RoadmapName = entity.RoadmapName,
            FitnessGoal = entity.FitnessGoal,
            CurrentPhase = entity.CurrentPhase,
            StartDate = entity.StartDate,
            ExpectedEndDate = entity.ExpectedEndDate,
            CurrentWeightKg = entity.CurrentWeightKg,
            TargetWeightKg = entity.TargetWeightKg,
            InitialFatPercentage = entity.InitialFatPercentage,
            TargetFatPercentage = entity.TargetFatPercentage,
            AdaptiveAiEnabled = entity.AdaptiveAiEnabled,
            AllowAiReschedule = entity.AllowAiReschedule,
            AllowAiIntensityAdjustment = entity.AllowAiIntensityAdjustment,
            AllowAiRecoveryDeload = entity.AllowAiRecoveryDeload,
            RoadmapStatus = entity.RoadmapStatus,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }

    public static PersonalizedRoadmap ToEntity(this CreatePersonalizedRoadmapDto dto)
    {
        return new PersonalizedRoadmap
        {
            UserId = dto.UserId,
            RoadmapName = dto.RoadmapName,
            FitnessGoal = dto.FitnessGoal,
            CurrentPhase = dto.CurrentPhase,
            StartDate = dto.StartDate,
            ExpectedEndDate = dto.ExpectedEndDate,
            CurrentWeightKg = dto.CurrentWeightKg,
            TargetWeightKg = dto.TargetWeightKg,
            InitialFatPercentage = dto.InitialFatPercentage,
            TargetFatPercentage = dto.TargetFatPercentage,
            AdaptiveAiEnabled = dto.AdaptiveAiEnabled,
            AllowAiReschedule = dto.AllowAiReschedule,
            AllowAiIntensityAdjustment = dto.AllowAiIntensityAdjustment,
            AllowAiRecoveryDeload = dto.AllowAiRecoveryDeload,
            RoadmapStatus = dto.RoadmapStatus
        };
    }

    public static void UpdateEntity(this PersonalizedRoadmap entity, UpdatePersonalizedRoadmapDto dto)
    {
        entity.RoadmapName = dto.RoadmapName;
        entity.FitnessGoal = dto.FitnessGoal;
        entity.CurrentPhase = dto.CurrentPhase;
        entity.StartDate = dto.StartDate;
        entity.ExpectedEndDate = dto.ExpectedEndDate;
        entity.CurrentWeightKg = dto.CurrentWeightKg;
        entity.TargetWeightKg = dto.TargetWeightKg;
        entity.InitialFatPercentage = dto.InitialFatPercentage;
        entity.TargetFatPercentage = dto.TargetFatPercentage;
        entity.AdaptiveAiEnabled = dto.AdaptiveAiEnabled;
        entity.AllowAiReschedule = dto.AllowAiReschedule;
        entity.AllowAiIntensityAdjustment = dto.AllowAiIntensityAdjustment;
        entity.AllowAiRecoveryDeload = dto.AllowAiRecoveryDeload;
        entity.RoadmapStatus = dto.RoadmapStatus;
    }

    // ── RecoveryProfile Extensions ───────────────────────────────────────────

    public static RecoveryProfileDto ToDto(this RecoveryProfile entity)
    {
        return new RecoveryProfileDto
        {
            Id = entity.Id,
            UserId = entity.UserId,
            CurrentRecoveryScore = entity.CurrentRecoveryScore,
            FatigueLevel = entity.FatigueLevel,
            MuscleSorenessScore = entity.MuscleSorenessScore,
            CnsFatigueScore = entity.CnsFatigueScore,
            RecommendedTrainingIntensity = entity.RecommendedTrainingIntensity,
            RecommendedWorkoutDuration = entity.RecommendedWorkoutDuration,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }

    public static RecoveryProfile ToEntity(this CreateRecoveryProfileDto dto)
    {
        return new RecoveryProfile
        {
            UserId = dto.UserId,
            CurrentRecoveryScore = dto.CurrentRecoveryScore,
            FatigueLevel = dto.FatigueLevel,
            MuscleSorenessScore = dto.MuscleSorenessScore,
            CnsFatigueScore = dto.CnsFatigueScore,
            RecommendedTrainingIntensity = dto.RecommendedTrainingIntensity,
            RecommendedWorkoutDuration = dto.RecommendedWorkoutDuration
        };
    }

    public static void UpdateEntity(this RecoveryProfile entity, UpdateRecoveryProfileDto dto)
    {
        entity.CurrentRecoveryScore = dto.CurrentRecoveryScore;
        entity.FatigueLevel = dto.FatigueLevel;
        entity.MuscleSorenessScore = dto.MuscleSorenessScore;
        entity.CnsFatigueScore = dto.CnsFatigueScore;
        entity.RecommendedTrainingIntensity = dto.RecommendedTrainingIntensity;
        entity.RecommendedWorkoutDuration = dto.RecommendedWorkoutDuration;
    }

    // ── ScheduledWorkout Extensions ──────────────────────────────────────────

    public static ScheduledWorkout ToEntity(this CreateScheduledWorkoutDto dto)
    {
        return new ScheduledWorkout
        {
            UserId = dto.UserId,
            SessionId = dto.SessionId,
            ScheduledStartTime = dto.ScheduledStartTime,
            ScheduledEndTime = dto.ScheduledEndTime,
            Status = dto.Status,
            RepeatPattern = dto.RepeatPattern
        };
    }

    public static void UpdateEntity(this ScheduledWorkout entity, UpdateScheduledWorkoutDto dto)
    {
        entity.UserId = dto.UserId;
        entity.SessionId = dto.SessionId;
        entity.ScheduledStartTime = dto.ScheduledStartTime;
        entity.ScheduledEndTime = dto.ScheduledEndTime;
        entity.Status = dto.Status;
        entity.RepeatPattern = dto.RepeatPattern;
    }

    // ── WorkoutExecutionLog Extensions ───────────────────────────────────────

    public static WorkoutExecutionLogDto ToLogDto(this WorkoutExecutionLog entity)
    {
        return new WorkoutExecutionLogDto
        {
            Id = entity.Id,
            UserId = entity.UserId,
            SessionId = entity.SessionId,
            StartedAt = entity.StartedAt,
            CompletedAt = entity.CompletedAt,
            ActualDurationMinutes = entity.ActualDurationMinutes,
            PerceivedDifficulty = entity.PerceivedDifficulty,
            EnergyLevelBefore = entity.EnergyLevelBefore,
            EnergyLevelAfter = entity.EnergyLevelAfter,
            CaloriesBurned = entity.CaloriesBurned,
            CompletionRate = entity.CompletionRate,
            AiCoachFeedback = entity.AiCoachFeedback,
            SkippedExercises = entity.SkippedExercises,
            SessionFeedback = entity.SessionFeedback,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }

    public static WorkoutExecutionLog ToEntity(this CreateWorkoutExecutionLogDto dto)
    {
        return new WorkoutExecutionLog
        {
            UserId = dto.UserId,
            SessionId = dto.SessionId,
            StartedAt = dto.StartedAt,
            CompletedAt = dto.CompletedAt,
            ActualDurationMinutes = dto.ActualDurationMinutes,
            PerceivedDifficulty = dto.PerceivedDifficulty,
            EnergyLevelBefore = dto.EnergyLevelBefore,
            EnergyLevelAfter = dto.EnergyLevelAfter,
            CaloriesBurned = dto.CaloriesBurned,
            CompletionRate = dto.CompletionRate,
            AiCoachFeedback = dto.AiCoachFeedback,
            SkippedExercises = dto.SkippedExercises,
            SessionFeedback = dto.SessionFeedback
        };
    }

    public static void UpdateEntity(this WorkoutExecutionLog entity, UpdateWorkoutExecutionLogDto dto)
    {
        entity.UserId = dto.UserId;
        entity.SessionId = dto.SessionId;
        entity.StartedAt = dto.StartedAt;
        entity.CompletedAt = dto.CompletedAt;
        entity.ActualDurationMinutes = dto.ActualDurationMinutes;
        entity.PerceivedDifficulty = dto.PerceivedDifficulty;
        entity.EnergyLevelBefore = dto.EnergyLevelBefore;
        entity.EnergyLevelAfter = dto.EnergyLevelAfter;
        entity.CaloriesBurned = dto.CaloriesBurned;
        entity.CompletionRate = dto.CompletionRate;
        entity.AiCoachFeedback = dto.AiCoachFeedback;
        entity.SkippedExercises = dto.SkippedExercises;
        entity.SessionFeedback = dto.SessionFeedback;
    }

    // ── UserCustomWorkout Update Extensions ──────────────────────────────────

    public static void UpdateEntity(this UserCustomWorkout entity, UpdateUserCustomWorkoutDto dto)
    {
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

    public static MyWorkoutDetailDto ToDetailDto(
        this UserCustomWorkout entity,
        List<RoadmapSession> sessions,
        List<ScheduledWorkout> schedules)
    {
        return new MyWorkoutDetailDto
        {
            Id = entity.Id,
            WorkoutName = entity.WorkoutName,
            Visibility = entity.Visibility,
            ParentWorkoutId = entity.ParentWorkoutId,
            SavesCount = entity.SavesCount,
            ScheduleMode = entity.ScheduleMode,
            AllowAiOptimization = entity.AllowAiOptimization,
            Sessions = sessions.Select(s => new WorkoutSessionDto
            {
                Id = s.Id,
                SessionTitle = s.SessionTitle,
                ExerciseCount = s.ExecutionBlocks.Count,
                TotalSetCount = s.ExecutionBlocks.Sum(b => b.TargetSets)
            }).ToList(),
            WeeklySchedules = schedules.Select(sc => new ScheduledWorkoutDto
            {
                Id = sc.Id,
                SessionId = sc.SessionId,
                SessionTitle = sessions.FirstOrDefault(s => s.Id == sc.SessionId)?.SessionTitle ?? string.Empty,
                ScheduledStartTime = sc.ScheduledStartTime,
                ScheduledEndTime = sc.ScheduledEndTime,
                RepeatPattern = sc.RepeatPattern,
                Status = sc.Status
            }).ToList()
        };
    }

    // ── RoadmapSession Extensions ────────────────────────────────────────────

    public static RoadmapSession ToEntity(this CreateRoadmapSessionDto dto)
    {
        return new RoadmapSession
        {
            RoadmapId = dto.RoadmapId,
            ScheduledDate = dto.ScheduledDate,
            ScheduledTime = dto.ScheduledTime,
            Timezone = dto.Timezone,
            SessionType = dto.SessionType,
            SessionTitle = dto.SessionTitle,
            EstimatedDurationMinutes = dto.EstimatedDurationMinutes,
            EnergyDemandScore = dto.EnergyDemandScore,
            RecoveryRequirementScore = dto.RecoveryRequirementScore,
            NotificationEnabled = dto.NotificationEnabled,
            NotificationMinutesBefore = dto.NotificationMinutesBefore,
            AiGenerated = dto.AiGenerated,
            SessionStatus = dto.SessionStatus,
            ExecutionBlocks = dto.ExecutionBlocks.Select(b => new RoadmapSession.ExecutionBlock
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

    public static void UpdateEntity(this RoadmapSession entity, UpdateRoadmapSessionDto dto)
    {
        entity.RoadmapId = dto.RoadmapId;
        entity.ScheduledDate = dto.ScheduledDate;
        entity.ScheduledTime = dto.ScheduledTime;
        entity.Timezone = dto.Timezone;
        entity.SessionType = dto.SessionType;
        entity.SessionTitle = dto.SessionTitle;
        entity.EstimatedDurationMinutes = dto.EstimatedDurationMinutes;
        entity.EnergyDemandScore = dto.EnergyDemandScore;
        entity.RecoveryRequirementScore = dto.RecoveryRequirementScore;
        entity.NotificationEnabled = dto.NotificationEnabled;
        entity.NotificationMinutesBefore = dto.NotificationMinutesBefore;
        entity.AiGenerated = dto.AiGenerated;
        entity.SessionStatus = dto.SessionStatus;
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
}
