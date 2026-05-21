using Exercise.Application.DTOs;
using Exercise.Domain.Models;

namespace Exercise.Application.Mappers;

public static class ApplicationMappers
{
    public static ExerciseCatalogDto ToDto(this ExerciseCatalog entity)
    {
        return new ExerciseCatalogDto
        {
            Id = entity.Id,
            ExerciseCode = entity.ExerciseCode,
            NameEn = entity.NameEn,
            NameVi = entity.NameVi,
            Slug = entity.Slug,
            Category = entity.Category,
            Difficulty = entity.Difficulty,
            MovementPattern = entity.MovementPattern,
            PrimaryMuscles = entity.PrimaryMuscles,
            SecondaryMuscles = entity.SecondaryMuscles,
            EquipmentRequired = entity.EquipmentRequired,
            IsCompound = entity.IsCompound,
            BodyRegion = entity.BodyRegion,
            EstimatedCaloriesPerMinute = entity.EstimatedCaloriesPerMinute,
            MetValue = entity.MetValue,
            RecommendedRestSeconds = entity.RecommendedRestSeconds,
            Contraindications = entity.Contraindications,
            RecommendedGoals = entity.RecommendedGoals,
            MovementTags = entity.MovementTags,
            AiCoachingCues = entity.AiCoachingCues,
            CommonMistakes = entity.CommonMistakes,
            RequiresSpotter = entity.RequiresSpotter,
            IsActive = entity.IsActive
        };
    }

    public static ExerciseCatalogDetailDto ToDetailDto(this ExerciseCatalog entity, IReadOnlyList<ExerciseMotionAssetDto> assets)
    {
        return new ExerciseCatalogDetailDto
        {
            Id = entity.Id,
            ExerciseCode = entity.ExerciseCode,
            NameEn = entity.NameEn,
            NameVi = entity.NameVi,
            Slug = entity.Slug,
            Category = entity.Category,
            Difficulty = entity.Difficulty,
            MovementPattern = entity.MovementPattern,
            PrimaryMuscles = entity.PrimaryMuscles,
            SecondaryMuscles = entity.SecondaryMuscles,
            EquipmentRequired = entity.EquipmentRequired,
            IsCompound = entity.IsCompound,
            BodyRegion = entity.BodyRegion,
            EstimatedCaloriesPerMinute = entity.EstimatedCaloriesPerMinute,
            MetValue = entity.MetValue,
            RecommendedRestSeconds = entity.RecommendedRestSeconds,
            Contraindications = entity.Contraindications,
            RecommendedGoals = entity.RecommendedGoals,
            MovementTags = entity.MovementTags,
            AiCoachingCues = entity.AiCoachingCues,
            CommonMistakes = entity.CommonMistakes,
            RequiresSpotter = entity.RequiresSpotter,
            MotionAssets = assets
        };
    }

    public static void UpdateEntity(this ExerciseCatalog entity, CreateExerciseCatalogDto dto)
    {
        entity.ExerciseCode = dto.ExerciseCode;
        entity.NameEn = dto.NameEn;
        entity.NameVi = dto.NameVi;
        entity.Slug = dto.Slug;
        entity.Category = dto.Category;
        entity.Difficulty = dto.Difficulty;
        entity.MovementPattern = dto.MovementPattern;
        entity.PrimaryMuscles = dto.PrimaryMuscles;
        entity.SecondaryMuscles = dto.SecondaryMuscles;
        entity.EquipmentRequired = dto.EquipmentRequired;
        entity.IsCompound = dto.IsCompound;
        entity.BodyRegion = dto.BodyRegion;
        entity.EstimatedCaloriesPerMinute = dto.EstimatedCaloriesPerMinute;
        entity.MetValue = dto.MetValue;
        entity.RecommendedRestSeconds = dto.RecommendedRestSeconds;
        entity.Contraindications = dto.Contraindications;
        entity.RecommendedGoals = dto.RecommendedGoals;
        entity.MovementTags = dto.MovementTags;
        entity.AiCoachingCues = dto.AiCoachingCues;
        entity.CommonMistakes = dto.CommonMistakes;
        entity.RequiresSpotter = dto.RequiresSpotter;
    }

    public static void UpdateEntity(this ExerciseCatalog entity, UpdateExerciseCatalogDto dto)
    {
        ((CreateExerciseCatalogDto)dto).UpdateEntity(entity);
        entity.IsActive = dto.IsActive;
    }
    
    private static void UpdateEntity(this CreateExerciseCatalogDto dto, ExerciseCatalog entity)
    {
        entity.ExerciseCode = dto.ExerciseCode;
        entity.NameEn = dto.NameEn;
        entity.NameVi = dto.NameVi;
        entity.Slug = dto.Slug;
        entity.Category = dto.Category;
        entity.Difficulty = dto.Difficulty;
        entity.MovementPattern = dto.MovementPattern;
        entity.PrimaryMuscles = dto.PrimaryMuscles;
        entity.SecondaryMuscles = dto.SecondaryMuscles;
        entity.EquipmentRequired = dto.EquipmentRequired;
        entity.IsCompound = dto.IsCompound;
        entity.BodyRegion = dto.BodyRegion;
        entity.EstimatedCaloriesPerMinute = dto.EstimatedCaloriesPerMinute;
        entity.MetValue = dto.MetValue;
        entity.RecommendedRestSeconds = dto.RecommendedRestSeconds;
        entity.Contraindications = dto.Contraindications;
        entity.RecommendedGoals = dto.RecommendedGoals;
        entity.MovementTags = dto.MovementTags;
        entity.AiCoachingCues = dto.AiCoachingCues;
        entity.CommonMistakes = dto.CommonMistakes;
        entity.RequiresSpotter = dto.RequiresSpotter;
    }

    public static ExerciseMotionAssetDto ToDto(this ExerciseMotionAsset entity)
    {
        return new ExerciseMotionAssetDto
        {
            Id = entity.Id,
            ExerciseId = entity.ExerciseId,
            AssetType = entity.AssetType,
            ResourceUrl = entity.ResourceUrl,
            ThumbnailUrl = entity.ThumbnailUrl,
            UnityPrefabId = entity.UnityPrefabId,
            UnityAnimationClip = entity.UnityAnimationClip,
            AnimationDurationSeconds = entity.AnimationDurationSeconds
        };
    }

    public static void UpdateEntity(this ExerciseMotionAsset entity, CreateExerciseMotionAssetDto dto)
    {
        entity.ExerciseId = dto.ExerciseId;
        entity.AssetType = dto.AssetType;
        entity.ResourceUrl = dto.ResourceUrl;
        entity.ThumbnailUrl = dto.ThumbnailUrl;
        entity.UnityPrefabId = dto.UnityPrefabId;
        entity.UnityAnimationClip = dto.UnityAnimationClip;
        entity.AnimationDurationSeconds = dto.AnimationDurationSeconds;
    }

    public static WorkoutTemplateDto ToDto(this WorkoutTemplate entity)
    {
        return new WorkoutTemplateDto
        {
            Id = entity.Id,
            Name = entity.Name,
            Goal = entity.Goal,
            Difficulty = entity.Difficulty,
            EstimatedDurationMinutes = entity.EstimatedDurationMinutes,
            TargetMuscleGroups = entity.TargetMuscleGroups,
            RequiredEquipment = entity.RequiredEquipment,
            EstimatedCaloriesBurn = entity.EstimatedCaloriesBurn,
            AiRecoveryScore = entity.AiRecoveryScore,
            IsSystemTemplate = entity.IsSystemTemplate,
            CreatedBy = entity.CreatedBy,
            Sessions = entity.Sessions.Select(x => new TemplateSessionBlockDto
            {
                Order = x.Order,
                ExerciseId = x.ExerciseId,
                Sets = x.Sets,
                MinReps = x.MinReps,
                MaxReps = x.MaxReps,
                RestSeconds = x.RestSeconds,
                Tempo = x.Tempo,
                Rir = x.Rir,
                Notes = x.Notes
            }).ToList()
        };
    }

    public static void UpdateEntity(this WorkoutTemplate entity, CreateWorkoutTemplateDto dto)
    {
        entity.Name = dto.Name;
        entity.Goal = dto.Goal;
        entity.Difficulty = dto.Difficulty;
        entity.EstimatedDurationMinutes = dto.EstimatedDurationMinutes;
        entity.EstimatedCaloriesBurn = dto.EstimatedCaloriesBurn;
        entity.AiRecoveryScore = dto.AiRecoveryScore;
        entity.IsSystemTemplate = dto.IsSystemTemplate;
        entity.CreatedBy = dto.CreatedBy;
        entity.Sessions = dto.Sessions.Select(x => new WorkoutTemplate.TemplateSessionBlock
        {
            Order = x.Order,
            ExerciseId = x.ExerciseId,
            Sets = x.Sets,
            MinReps = x.MinReps,
            MaxReps = x.MaxReps,
            RestSeconds = x.RestSeconds,
            Tempo = x.Tempo,
            Rir = x.Rir,
            Notes = x.Notes
        }).ToList();
    }
}
