using Exercise.Domain.Models;
using Libs.Shared.Enums;
using MongoDB.Driver;

namespace Exercise.Infrastructure.Persistence.Seed;

public static class ExerciseSeedData
{
    public static List<ExerciseCatalog> GetExerciseCatalogs()
    {
        return
        [
            new ExerciseCatalog
        {
            Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
            ExerciseCode = "PUSH_UP",
            NameEn = "Push Up",
            NameVi = "Chống đẩy",
            Slug = "push-up",
            Category = ExerciseCategory.Strength,
            Difficulty = Difficulty.Beginner,
            MovementPattern = MovementPattern.HorizontalPush,
            PrimaryMuscles = ["Chest", "Triceps"],
            SecondaryMuscles = ["Shoulders", "Core"],
            EquipmentRequired = [],
            IsCompound = true,
            BodyRegion = BodyRegion.UpperBody,
            EstimatedCaloriesPerMinute = 7,
            MetValue = 3.8m,
            RecommendedRestSeconds = 60,
            Contraindications = ["Wrist injury", "Shoulder pain"],
            RecommendedGoals = ["Strength", "MuscleGain", "FatLoss"],
            MovementTags = ["HorizontalPush", "Bodyweight", "UpperBody"],
            AiCoachingCues =
            [
                "Keep your body in a straight line",
                "Lower your chest under control",
                "Do not flare your elbows too much"
            ],
            CommonMistakes =
            [
                "Sagging hips",
                "Flaring elbows",
                "Incomplete range of motion"
            ],
            RequiresSpotter = false,
            IsActive = true
        },

        new ExerciseCatalog
        {
            Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
            ExerciseCode = "BODYWEIGHT_SQUAT",
            NameEn = "Bodyweight Squat",
            NameVi = "Squat không tạ",
            Slug = "bodyweight-squat",
            Category = ExerciseCategory.Strength,
            Difficulty = Difficulty.Beginner,
            MovementPattern = MovementPattern.Squat,
            PrimaryMuscles = ["Quadriceps", "Glutes"],
            SecondaryMuscles = ["Hamstrings", "Core"],
            EquipmentRequired = [],
            IsCompound = true,
            BodyRegion = BodyRegion.LowerBody,
            EstimatedCaloriesPerMinute = 6,
            MetValue = 3.5m,
            RecommendedRestSeconds = 60,
            Contraindications = ["Knee injury", "Hip pain"],
            RecommendedGoals = ["Strength", "Mobility", "FatLoss"],
            MovementTags = ["Squat", "Bodyweight", "LowerBody"],
            AiCoachingCues =
            [
                "Keep your chest up",
                "Push your knees in line with your toes",
                "Drive through your heels"
            ],
            CommonMistakes =
            [
                "Knees collapsing inward",
                "Heels lifting off the ground",
                "Rounding the back"
            ],
            RequiresSpotter = false,
            IsActive = true
        },

        new ExerciseCatalog
        {
            Id = Guid.Parse("33333333-3333-3333-3333-333333333333"),
            ExerciseCode = "PLANK",
            NameEn = "Plank",
            NameVi = "Plank",
            Slug = "plank",
            Category = ExerciseCategory.Strength,
            Difficulty = Difficulty.Beginner,
            MovementPattern = MovementPattern.Core,
            PrimaryMuscles = ["Core", "Abs"],
            SecondaryMuscles = ["Shoulders", "Glutes"],
            EquipmentRequired = [],
            IsCompound = true,
            BodyRegion = BodyRegion.Core,
            EstimatedCaloriesPerMinute = 4,
            MetValue = 2.8m,
            RecommendedRestSeconds = 45,
            Contraindications = ["Lower back pain", "Shoulder pain"],
            RecommendedGoals = ["CoreStrength", "Stability", "FatLoss"],
            MovementTags = ["Core", "Isometric", "Bodyweight"],
            AiCoachingCues =
            [
                "Brace your core",
                "Keep your hips level",
                "Do not hold your breath"
            ],
            CommonMistakes =
            [
                "Hips too high",
                "Lower back sagging",
                "Neck overextended"
            ],
            RequiresSpotter = false,
            IsActive = true
        },

        new ExerciseCatalog
        {
            Id = Guid.Parse("44444444-4444-4444-4444-444444444444"),
            ExerciseCode = "FORWARD_LUNGE",
            NameEn = "Forward Lunge",
            NameVi = "Chùng chân trước",
            Slug = "forward-lunge",
            Category = ExerciseCategory.Strength,
            Difficulty = Difficulty.Intermediate,
            MovementPattern = MovementPattern.Squat,
            PrimaryMuscles = ["Quadriceps", "Glutes"],
            SecondaryMuscles = ["Hamstrings", "Calves", "Core"],
            EquipmentRequired = [],
            IsCompound = true,
            BodyRegion = BodyRegion.LowerBody,
            EstimatedCaloriesPerMinute = 7,
            MetValue = 4.0m,
            RecommendedRestSeconds = 60,
            Contraindications = ["Knee injury", "Balance problems"],
            RecommendedGoals = ["Strength", "Balance", "FatLoss"],
            MovementTags = ["Lunge", "Unilateral", "LowerBody"],
            AiCoachingCues =
            [
                "Step forward with control",
                "Keep your front knee aligned with your toes",
                "Push back through the front heel"
            ],
            CommonMistakes =
            [
                "Front knee passing too far forward",
                "Losing balance",
                "Leaning torso too much"
            ],
            RequiresSpotter = false,
            IsActive = true
        },

        new ExerciseCatalog
        {
            Id = Guid.Parse("55555555-5555-5555-5555-555555555555"),
            ExerciseCode = "JUMPING_JACK",
            NameEn = "Jumping Jack",
            NameVi = "Nhảy dang tay chân",
            Slug = "jumping-jack",
            Category = ExerciseCategory.Cardio,
            Difficulty = Difficulty.Beginner,
            MovementPattern = MovementPattern.Core,
            PrimaryMuscles = ["Full Body"],
            SecondaryMuscles = ["Shoulders", "Calves", "Core"],
            EquipmentRequired = [],
            IsCompound = true,
            BodyRegion = BodyRegion.FullBody,
            EstimatedCaloriesPerMinute = 8,
            MetValue = 4.5m,
            RecommendedRestSeconds = 30,
            Contraindications = ["Knee injury", "Ankle injury"],
            RecommendedGoals = ["FatLoss", "Endurance", "WarmUp"],
            MovementTags = ["Cardio", "Bodyweight", "FullBody"],
            AiCoachingCues =
            [
                "Land softly",
                "Keep a steady rhythm",
                "Move your arms fully overhead"
            ],
            CommonMistakes =
            [
                "Landing too hard",
                "Poor coordination",
                "Not opening arms and legs fully"
            ],
            RequiresSpotter = false,
            IsActive = true
        }
        ];
    }
    public static List<WorkoutTemplate> GetWorkoutTemplates()
    {
        return
        [
            new WorkoutTemplate
        {
            Id = Guid.Parse("99999999-9999-9999-9999-999999999991"),
            Name = "Beginner Full Body Workout",
            Goal = "Build basic strength and movement control",
            Difficulty = Difficulty.Beginner,
            EstimatedDurationMinutes = 30,
            TargetMuscleGroups = ["Chest", "Legs", "Core", "Full Body"],
            RequiredEquipment = [],
            EstimatedCaloriesBurn = 180,
            AiRecoveryScore = 75,
            IsSystemTemplate = true,
            CreatedBy = "system",
            Sessions =
            [
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 1,
                    ExerciseId = Guid.Parse("55555555-5555-5555-5555-555555555555"),
                    Sets = 3,
                    MinReps = 30,
                    MaxReps = 45,
                    RestSeconds = 30,
                    Tempo = "Normal",
                    Rir = 2,
                    Notes = "Use as warm-up. Count by seconds instead of reps."
                },
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 2,
                    ExerciseId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    Sets = 3,
                    MinReps = 10,
                    MaxReps = 15,
                    RestSeconds = 60,
                    Tempo = "2-1-2",
                    Rir = 2,
                    Notes = "Focus on controlled depth."
                },
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 3,
                    ExerciseId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    Sets = 3,
                    MinReps = 8,
                    MaxReps = 12,
                    RestSeconds = 60,
                    Tempo = "2-0-2",
                    Rir = 2,
                    Notes = "Modify on knees if needed."
                },
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 4,
                    ExerciseId = Guid.Parse("33333333-3333-3333-3333-333333333333"),
                    Sets = 3,
                    MinReps = 20,
                    MaxReps = 40,
                    RestSeconds = 45,
                    Tempo = "Hold",
                    Rir = 1,
                    Notes = "Hold plank for seconds."
                }
            ]
        },

        new WorkoutTemplate
        {
            Id = Guid.Parse("99999999-9999-9999-9999-999999999992"),
            Name = "Lower Body Foundation",
            Goal = "Improve leg strength and balance",
            Difficulty = Difficulty.Intermediate,
            EstimatedDurationMinutes = 35,
            TargetMuscleGroups = ["Quadriceps", "Glutes", "Hamstrings", "Core"],
            RequiredEquipment = [],
            EstimatedCaloriesBurn = 220,
            AiRecoveryScore = 70,
            IsSystemTemplate = true,
            CreatedBy = "system",
            Sessions =
            [
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 1,
                    ExerciseId = Guid.Parse("55555555-5555-5555-5555-555555555555"),
                    Sets = 3,
                    MinReps = 30,
                    MaxReps = 45,
                    RestSeconds = 30,
                    Tempo = "Normal",
                    Rir = 2,
                    Notes = "Warm up with light cardio."
                },
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 2,
                    ExerciseId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    Sets = 4,
                    MinReps = 12,
                    MaxReps = 15,
                    RestSeconds = 60,
                    Tempo = "3-1-2",
                    Rir = 2,
                    Notes = "Keep knees aligned with toes."
                },
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 3,
                    ExerciseId = Guid.Parse("44444444-4444-4444-4444-444444444444"),
                    Sets = 3,
                    MinReps = 8,
                    MaxReps = 12,
                    RestSeconds = 75,
                    Tempo = "2-1-2",
                    Rir = 2,
                    Notes = "Perform reps per leg."
                },
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 4,
                    ExerciseId = Guid.Parse("33333333-3333-3333-3333-333333333333"),
                    Sets = 3,
                    MinReps = 30,
                    MaxReps = 45,
                    RestSeconds = 45,
                    Tempo = "Hold",
                    Rir = 1,
                    Notes = "Core finisher."
                }
            ]
        },

        new WorkoutTemplate
        {
            Id = Guid.Parse("99999999-9999-9999-9999-999999999993"),
            Name = "Fat Loss Bodyweight Circuit",
            Goal = "Burn calories and improve endurance",
            Difficulty = Difficulty.Intermediate,
            EstimatedDurationMinutes = 25,
            TargetMuscleGroups = ["Full Body", "Chest", "Legs", "Core"],
            RequiredEquipment = [],
            EstimatedCaloriesBurn = 260,
            AiRecoveryScore = 65,
            IsSystemTemplate = true,
            CreatedBy = "system",
            Sessions =
            [
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 1,
                    ExerciseId = Guid.Parse("55555555-5555-5555-5555-555555555555"),
                    Sets = 4,
                    MinReps = 30,
                    MaxReps = 45,
                    RestSeconds = 30,
                    Tempo = "Fast",
                    Rir = 2,
                    Notes = "Keep intensity moderate to high."
                },
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 2,
                    ExerciseId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    Sets = 4,
                    MinReps = 8,
                    MaxReps = 15,
                    RestSeconds = 45,
                    Tempo = "2-0-2",
                    Rir = 2,
                    Notes = "Use incline push-up if too difficult."
                },
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 3,
                    ExerciseId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    Sets = 4,
                    MinReps = 12,
                    MaxReps = 20,
                    RestSeconds = 45,
                    Tempo = "2-1-2",
                    Rir = 2,
                    Notes = "Maintain steady pace."
                },
                new WorkoutTemplate.TemplateSessionBlock
                {
                    Order = 4,
                    ExerciseId = Guid.Parse("33333333-3333-3333-3333-333333333333"),
                    Sets = 4,
                    MinReps = 20,
                    MaxReps = 40,
                    RestSeconds = 30,
                    Tempo = "Hold",
                    Rir = 1,
                    Notes = "Hold plank at the end of each round."
                }
            ]
        }
        ];
    }
    public static List<ExerciseMotionAsset> GetExerciseMotionAssets()
    {
        return
        [
            new ExerciseMotionAsset
        {
            Id = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
            ExerciseId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
            AssetType = AssetType.Video,
            ResourceUrl = "https://cdn.example.com/exercises/videos/push-up.mp4",
            ThumbnailUrl = "https://cdn.example.com/exercises/thumbnails/push-up.jpg",
            UnityPrefabId = null,
            UnityAnimationClip = null,
            AnimationDurationSeconds = 30
        },

        new ExerciseMotionAsset
        {
            Id = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"),
            ExerciseId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
            AssetType = AssetType.Video,
            ResourceUrl = "https://cdn.example.com/exercises/videos/bodyweight-squat.mp4",
            ThumbnailUrl = "https://cdn.example.com/exercises/thumbnails/bodyweight-squat.jpg",
            UnityPrefabId = null,
            UnityAnimationClip = null,
            AnimationDurationSeconds = 35
        },

        new ExerciseMotionAsset
        {
            Id = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc"),
            ExerciseId = Guid.Parse("33333333-3333-3333-3333-333333333333"),
            AssetType = AssetType.Video,
            ResourceUrl = "https://cdn.example.com/exercises/videos/plank.mp4",
            ThumbnailUrl = "https://cdn.example.com/exercises/thumbnails/plank.jpg",
            UnityPrefabId = null,
            UnityAnimationClip = null,
            AnimationDurationSeconds = 40
        },

        new ExerciseMotionAsset
        {
            Id = Guid.Parse("dddddddd-dddd-dddd-dddd-dddddddddddd"),
            ExerciseId = Guid.Parse("44444444-4444-4444-4444-444444444444"),
            AssetType = AssetType.Video,
            ResourceUrl = "https://cdn.example.com/exercises/videos/forward-lunge.mp4",
            ThumbnailUrl = "https://cdn.example.com/exercises/thumbnails/forward-lunge.jpg",
            UnityPrefabId = null,
            UnityAnimationClip = null,
            AnimationDurationSeconds = 35
        },

        new ExerciseMotionAsset
        {
            Id = Guid.Parse("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"),
            ExerciseId = Guid.Parse("55555555-5555-5555-5555-555555555555"),
            AssetType = AssetType.Video,
            ResourceUrl = "https://cdn.example.com/exercises/videos/jumping-jack.mp4",
            ThumbnailUrl = "https://cdn.example.com/exercises/thumbnails/jumping-jack.jpg",
            UnityPrefabId = null,
            UnityAnimationClip = null,
            AnimationDurationSeconds = 30
        }
        ];
    }
    public static class ExerciseMongoSeeder
    {
        public static async Task SeedAsync(IMongoDatabase database)
        {
            var exerciseCollection = database.GetCollection<ExerciseCatalog>("ExerciseCatalog");
            var assetCollection = database.GetCollection<ExerciseMotionAsset>("ExerciseMotionAsset");
            var templateCollection = database.GetCollection<WorkoutTemplate>("WorkoutTemplate");

            if (!await exerciseCollection.Find(_ => true).AnyAsync())
            {
                await exerciseCollection.InsertManyAsync(
                    ExerciseSeedData.GetExerciseCatalogs());
            }

            if (!await assetCollection.Find(_ => true).AnyAsync())
            {
                await assetCollection.InsertManyAsync(
                    ExerciseSeedData.GetExerciseMotionAssets());
            }

            if (!await templateCollection.Find(_ => true).AnyAsync())
            {
                await templateCollection.InsertManyAsync(
                    ExerciseSeedData.GetWorkoutTemplates());
            }
        }
    }
}