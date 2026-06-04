using Libs.Shared.Enums;
using MongoDB.Driver;
using Roadmap.Domain.Models;

namespace Roadmap.Infrastructure.Persistence.Seed;

public static class RoadmapSeedData
{
    // ── Cross-service IDs (must match IamSeedData / ExerciseSeedData) ─────────
    public static readonly Guid DemoUserId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    public static readonly Guid AdminUserId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    public static readonly Guid PartnerUserId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");

    public static readonly Guid PushUpExerciseId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    public static readonly Guid SquatExerciseId = Guid.Parse("22222222-2222-2222-2222-222222222222");
    public static readonly Guid PlankExerciseId = Guid.Parse("33333333-3333-3333-3333-333333333333");
    public static readonly Guid BurpeeExerciseId = Guid.Parse("44444444-4444-4444-4444-444444444444");

    // ── Stable document IDs ───────────────────────────────────────────────────
    public static readonly Guid DemoRoadmapId = Guid.Parse("f1000001-0000-0000-0000-000000000001");
    public static readonly Guid AdminRoadmapId = Guid.Parse("f1000002-0000-0000-0000-000000000002");
    public static readonly Guid PartnerRoadmapId = Guid.Parse("f1000003-0000-0000-0000-000000000003");

    public static readonly Guid DemoRecoveryId = Guid.Parse("f2000001-0000-0000-0000-000000000001");
    public static readonly Guid AdminRecoveryId = Guid.Parse("f2000002-0000-0000-0000-000000000002");
    public static readonly Guid PartnerRecoveryId = Guid.Parse("f2000003-0000-0000-0000-000000000003");

    public static readonly Guid DemoCustomWorkoutId = Guid.Parse("f3000001-0000-0000-0000-000000000001");
    public static readonly Guid PartnerCustomWorkoutId = Guid.Parse("f3000002-0000-0000-0000-000000000002");

    public static readonly Guid DemoSessionScheduledId = Guid.Parse("f4000001-0000-0000-0000-000000000001");
    public static readonly Guid DemoSessionCompletedId = Guid.Parse("f4000002-0000-0000-0000-000000000002");
    public static readonly Guid AdminSessionScheduledId = Guid.Parse("f4000003-0000-0000-0000-000000000003");
    public static readonly Guid CustomWorkoutSession1Id = Guid.Parse("f4000004-0000-0000-0000-000000000004");
    public static readonly Guid CustomWorkoutSession2Id = Guid.Parse("f4000005-0000-0000-0000-000000000005");
    public static readonly Guid PartnerCustomWorkoutSessionId = Guid.Parse("f4000006-0000-0000-0000-000000000006");

    public static readonly Guid DemoScheduledWorkoutId = Guid.Parse("f5000001-0000-0000-0000-000000000001");
    public static readonly Guid AdminScheduledWorkoutId = Guid.Parse("f5000002-0000-0000-0000-000000000002");

    public static readonly Guid DemoExecutionLogId = Guid.Parse("f6000001-0000-0000-0000-000000000001");
    public static readonly Guid DemoSetLog1Id = Guid.Parse("f7000001-0000-0000-0000-000000000001");
    public static readonly Guid DemoSetLog2Id = Guid.Parse("f7000002-0000-0000-0000-000000000002");
    public static readonly Guid DemoSetLog3Id = Guid.Parse("f7000003-0000-0000-0000-000000000003");

    public static IReadOnlyList<PersonalizedRoadmap> GetPersonalizedRoadmaps(DateTimeOffset utcNow) =>
    [
        new PersonalizedRoadmap
        {
            Id = DemoRoadmapId,
            UserId = DemoUserId,
            RoadmapName = "Demo Fat Loss 12W",
            FitnessGoal = "FatLoss",
            CurrentPhase = "Foundation",
            StartDate = utcNow.AddDays(-28),
            ExpectedEndDate = utcNow.AddDays(56),
            CurrentWeightKg = 78,
            TargetWeightKg = 72,
            InitialFatPercentage = 22,
            TargetFatPercentage = 16,
            AdaptiveAiEnabled = true,
            AllowAiReschedule = true,
            AllowAiIntensityAdjustment = true,
            AllowAiRecoveryDeload = true,
            RoadmapStatus = RoadmapStatus.Active,
        },
        new PersonalizedRoadmap
        {
            Id = AdminRoadmapId,
            UserId = AdminUserId,
            RoadmapName = "Admin Maintenance",
            FitnessGoal = "GeneralHealth",
            CurrentPhase = "Maintenance",
            StartDate = utcNow.AddDays(-60),
            ExpectedEndDate = utcNow.AddDays(120),
            CurrentWeightKg = 70,
            TargetWeightKg = 70,
            InitialFatPercentage = 18,
            TargetFatPercentage = 18,
            AdaptiveAiEnabled = true,
            AllowAiReschedule = false,
            AllowAiIntensityAdjustment = true,
            AllowAiRecoveryDeload = true,
            RoadmapStatus = RoadmapStatus.Active,
        },
        new PersonalizedRoadmap
        {
            Id = PartnerRoadmapId,
            UserId = PartnerUserId,
            RoadmapName = "Partner Strength Block",
            FitnessGoal = "MuscleGain",
            CurrentPhase = "Hypertrophy",
            StartDate = utcNow.AddDays(-14),
            ExpectedEndDate = utcNow.AddDays(42),
            CurrentWeightKg = 82,
            TargetWeightKg = 85,
            InitialFatPercentage = 15,
            TargetFatPercentage = 14,
            AdaptiveAiEnabled = true,
            AllowAiReschedule = true,
            AllowAiIntensityAdjustment = true,
            AllowAiRecoveryDeload = false,
            RoadmapStatus = RoadmapStatus.Active,
        },
    ];

    public static IReadOnlyList<RecoveryProfile> GetRecoveryProfiles() =>
    [
        new RecoveryProfile
        {
            Id = DemoRecoveryId,
            UserId = DemoUserId,
            CurrentRecoveryScore = 72,
            FatigueLevel = 3,
            SleepRecoveryScore = 70,
            MuscleSorenessScore = 4,
            CnsFatigueScore = 3,
            RecommendedTrainingIntensity = "Moderate",
            RecommendedWorkoutDuration = 45,
        },
        new RecoveryProfile
        {
            Id = AdminRecoveryId,
            UserId = AdminUserId,
            CurrentRecoveryScore = 88,
            FatigueLevel = 2,
            SleepRecoveryScore = 85,
            MuscleSorenessScore = 2,
            CnsFatigueScore = 2,
            RecommendedTrainingIntensity = "Light",
            RecommendedWorkoutDuration = 30,
        },
        new RecoveryProfile
        {
            Id = PartnerRecoveryId,
            UserId = PartnerUserId,
            CurrentRecoveryScore = 65,
            FatigueLevel = 4,
            SleepRecoveryScore = 60,
            MuscleSorenessScore = 5,
            CnsFatigueScore = 4,
            RecommendedTrainingIntensity = "Moderate",
            RecommendedWorkoutDuration = 50,
        },
    ];

    public static IReadOnlyList<UserCustomWorkout> GetUserCustomWorkouts() =>
    [
        new UserCustomWorkout
        {
            Id = DemoCustomWorkoutId,
            UserId = DemoUserId,
            WorkoutName = "Demo Upper Push",
            Visibility = Visibility.Private,
            ScheduleMode = "manual",
            AllowAiOptimization = true,
            CustomBlocks =
            [
                new UserCustomWorkout.CustomBlock
                {
                    ExerciseId = PushUpExerciseId,
                    Sets = 3,
                    Reps = 12,
                    WeightKg = 0,
                    RestSeconds = 60,
                },
                new UserCustomWorkout.CustomBlock
                {
                    ExerciseId = PlankExerciseId,
                    Sets = 3,
                    Reps = 45,
                    WeightKg = 0,
                    RestSeconds = 45,
                },
            ],
        },
        new UserCustomWorkout
        {
            Id = PartnerCustomWorkoutId,
            UserId = PartnerUserId,
            WorkoutName = "Partner HIIT Template",
            Visibility = Visibility.Public,
            ScheduleMode = "manual",
            AllowAiOptimization = true,
            CustomBlocks =
            [
                new UserCustomWorkout.CustomBlock
                {
                    ExerciseId = BurpeeExerciseId,
                    Sets = 4,
                    Reps = 10,
                    WeightKg = 0,
                    RestSeconds = 90,
                },
                new UserCustomWorkout.CustomBlock
                {
                    ExerciseId = SquatExerciseId,
                    Sets = 4,
                    Reps = 15,
                    WeightKg = 20,
                    RestSeconds = 75,
                },
            ],
        },
    ];

    public static IReadOnlyList<RoadmapSession> GetRoadmapSessions(DateTimeOffset utcNow)
    {
        var tomorrowMorning = utcNow.Date.AddDays(1).AddHours(7);
        var twoDaysAgoMorning = utcNow.Date.AddDays(-2).AddHours(7);
        var nextWeekMorning = utcNow.Date.AddDays(7).AddHours(8);

        return
        [
            new RoadmapSession
            {
                Id = DemoSessionScheduledId,
                RoadmapId = DemoRoadmapId,
                ScheduledDate = tomorrowMorning,
                ScheduledTime = "07:00",
                Timezone = "Asia/Ho_Chi_Minh",
                SessionType = "Strength",
                SessionTitle = "Demo Push Day",
                EstimatedDurationMinutes = 45,
                EnergyDemandScore = 6,
                RecoveryRequirementScore = 5,
                NotificationEnabled = true,
                NotificationMinutesBefore = 30,
                AiGenerated = true,
                SessionStatus = SessionStatus.Scheduled,
                ExecutionBlocks =
                [
                    new RoadmapSession.ExecutionBlock
                    {
                        Order = 1,
                        ExerciseId = PushUpExerciseId,
                        ExerciseName = "Push Up",
                        TargetSets = 3,
                        TargetReps = 12,
                        TargetWeightKg = 0,
                        RestSeconds = 60,
                        Tempo = "2010",
                    },
                    new RoadmapSession.ExecutionBlock
                    {
                        Order = 2,
                        ExerciseId = PlankExerciseId,
                        ExerciseName = "Plank",
                        TargetSets = 3,
                        TargetReps = 45,
                        TargetWeightKg = 0,
                        RestSeconds = 45,
                        Tempo = "static",
                    },
                ],
            },
            new RoadmapSession
            {
                Id = DemoSessionCompletedId,
                RoadmapId = DemoRoadmapId,
                ScheduledDate = twoDaysAgoMorning,
                ScheduledTime = "07:00",
                Timezone = "Asia/Ho_Chi_Minh",
                SessionType = "Strength",
                SessionTitle = "Demo Pull & Core",
                EstimatedDurationMinutes = 40,
                EnergyDemandScore = 5,
                RecoveryRequirementScore = 4,
                NotificationEnabled = false,
                NotificationMinutesBefore = 0,
                AiGenerated = false,
                SessionStatus = SessionStatus.Completed,
                ExecutionBlocks =
                [
                    new RoadmapSession.ExecutionBlock
                    {
                        Order = 1,
                        ExerciseId = SquatExerciseId,
                        ExerciseName = "Squat",
                        TargetSets = 3,
                        TargetReps = 10,
                        TargetWeightKg = 40,
                        RestSeconds = 90,
                        Tempo = "3010",
                    },
                ],
            },
            new RoadmapSession
            {
                Id = AdminSessionScheduledId,
                RoadmapId = AdminRoadmapId,
                ScheduledDate = nextWeekMorning,
                ScheduledTime = "08:00",
                Timezone = "Asia/Ho_Chi_Minh",
                SessionType = "Mobility",
                SessionTitle = "Admin Recovery Flow",
                EstimatedDurationMinutes = 30,
                EnergyDemandScore = 3,
                RecoveryRequirementScore = 2,
                NotificationEnabled = true,
                NotificationMinutesBefore = 15,
                AiGenerated = true,
                SessionStatus = SessionStatus.Scheduled,
                ExecutionBlocks =
                [
                    new RoadmapSession.ExecutionBlock
                    {
                        Order = 1,
                        ExerciseId = PlankExerciseId,
                        ExerciseName = "Plank",
                        TargetSets = 2,
                        TargetReps = 60,
                        TargetWeightKg = 0,
                        RestSeconds = 30,
                        Tempo = "static",
                    },
                ],
            },
            new RoadmapSession
            {
                Id = CustomWorkoutSession1Id,
                RoadmapId = DemoCustomWorkoutId,
                ScheduledDate = tomorrowMorning,
                ScheduledTime = "19:00",
                Timezone = "Asia/Ho_Chi_Minh",
                SessionType = "Strength",
                SessionTitle = "Push Focus",
                EstimatedDurationMinutes = 45,
                EnergyDemandScore = 5,
                RecoveryRequirementScore = 5,
                NotificationEnabled = true,
                NotificationMinutesBefore = 30,
                AiGenerated = false,
                SessionStatus = SessionStatus.Scheduled,
                ExecutionBlocks =
                [
                    new RoadmapSession.ExecutionBlock
                    {
                        Order = 1,
                        ExerciseId = PushUpExerciseId,
                        ExerciseName = "Push Up",
                        TargetSets = 3,
                        TargetReps = 12,
                        TargetWeightKg = 0,
                        RestSeconds = 60,
                        Tempo = "3010",
                    },
                    new RoadmapSession.ExecutionBlock
                    {
                        Order = 2,
                        ExerciseId = PlankExerciseId,
                        ExerciseName = "Plank",
                        TargetSets = 3,
                        TargetReps = 45,
                        TargetWeightKg = 0,
                        RestSeconds = 45,
                        Tempo = "static",
                    },
                ],
            },
            new RoadmapSession
            {
                Id = CustomWorkoutSession2Id,
                RoadmapId = DemoCustomWorkoutId,
                ScheduledDate = nextWeekMorning,
                ScheduledTime = "19:00",
                Timezone = "Asia/Ho_Chi_Minh",
                SessionType = "Strength",
                SessionTitle = "Plank Focus",
                EstimatedDurationMinutes = 45,
                EnergyDemandScore = 5,
                RecoveryRequirementScore = 5,
                NotificationEnabled = true,
                NotificationMinutesBefore = 30,
                AiGenerated = false,
                SessionStatus = SessionStatus.Scheduled,
                ExecutionBlocks =
                [
                    new RoadmapSession.ExecutionBlock
                    {
                        Order = 1,
                        ExerciseId = PushUpExerciseId,
                        ExerciseName = "Push Up",
                        TargetSets = 3,
                        TargetReps = 12,
                        TargetWeightKg = 0,
                        RestSeconds = 60,
                        Tempo = "3010",
                    },
                    new RoadmapSession.ExecutionBlock
                    {
                        Order = 2,
                        ExerciseId = PlankExerciseId,
                        ExerciseName = "Plank",
                        TargetSets = 3,
                        TargetReps = 45,
                        TargetWeightKg = 0,
                        RestSeconds = 45,
                        Tempo = "static",
                    },
                ],
            },
            new RoadmapSession
            {
                Id = PartnerCustomWorkoutSessionId,
                RoadmapId = PartnerCustomWorkoutId,
                ScheduledDate = tomorrowMorning,
                ScheduledTime = "07:00",
                Timezone = "Asia/Ho_Chi_Minh",
                SessionType = "Cardio",
                SessionTitle = "Partner HIIT Day",
                EstimatedDurationMinutes = 50,
                EnergyDemandScore = 7,
                RecoveryRequirementScore = 6,
                NotificationEnabled = true,
                NotificationMinutesBefore = 30,
                AiGenerated = false,
                SessionStatus = SessionStatus.Scheduled,
                ExecutionBlocks =
                [
                    new RoadmapSession.ExecutionBlock
                    {
                        Order = 1,
                        ExerciseId = BurpeeExerciseId,
                        ExerciseName = "Burpee",
                        TargetSets = 4,
                        TargetReps = 10,
                        TargetWeightKg = 0,
                        RestSeconds = 90,
                        Tempo = "fast",
                    },
                    new RoadmapSession.ExecutionBlock
                    {
                        Order = 2,
                        ExerciseId = SquatExerciseId,
                        ExerciseName = "Squat",
                        TargetSets = 4,
                        TargetReps = 15,
                        TargetWeightKg = 20,
                        RestSeconds = 75,
                        Tempo = "3010",
                    },
                ],
            },
        ];
    }

    public static IReadOnlyList<ScheduledWorkout> GetScheduledWorkouts(DateTimeOffset utcNow)
    {
        var demoStart = utcNow.Date.AddDays(1).AddHours(7);
        var adminStart = utcNow.Date.AddDays(7).AddHours(8);

        return
        [
            new ScheduledWorkout
            {
                Id = DemoScheduledWorkoutId,
                UserId = DemoUserId,
                SessionId = DemoSessionScheduledId,
                ScheduledStartTime = demoStart,
                ScheduledEndTime = demoStart.AddMinutes(45),
                RepeatPattern = "none",
                Status = SessionStatus.Scheduled,
            },
            new ScheduledWorkout
            {
                Id = AdminScheduledWorkoutId,
                UserId = AdminUserId,
                SessionId = AdminSessionScheduledId,
                ScheduledStartTime = adminStart,
                ScheduledEndTime = adminStart.AddMinutes(30),
                RepeatPattern = "none",
                Status = SessionStatus.Scheduled,
            },
        ];
    }

    public static IReadOnlyList<WorkoutExecutionLog> GetWorkoutExecutionLogs(DateTimeOffset utcNow)
    {
        var started = utcNow.Date.AddDays(-2).AddHours(7);
        var completed = started.AddMinutes(38);

        return
        [
            new WorkoutExecutionLog
            {
                Id = DemoExecutionLogId,
                UserId = DemoUserId,
                SessionId = DemoSessionCompletedId,
                StartedAt = started,
                CompletedAt = completed,
                ActualDurationMinutes = 38,
                PerceivedDifficulty = 6,
                EnergyLevelBefore = 7,
                EnergyLevelAfter = 5,
                CaloriesBurned = 280,
                CompletionRate = 95,
                AiCoachFeedback = "Form ổn định; có thể tăng nhẹ tạ squat tuần sau.",
                SkippedExercises = [],
                SessionFeedback = "Cảm thấy tốt sau buổi tập.",
            },
        ];
    }

    public static IReadOnlyList<ExerciseSetLog> GetExerciseSetLogs() =>
    [
        new ExerciseSetLog
        {
            Id = DemoSetLog1Id,
            ExecutionId = DemoExecutionLogId,
            ExerciseId = SquatExerciseId,
            SetNumber = 1,
            TargetReps = 10,
            ActualReps = 10,
            WeightKg = 40,
            Rir = 2,
            RestTakenSeconds = 95,
            FormScore = 88,
            Completed = true,
        },
        new ExerciseSetLog
        {
            Id = DemoSetLog2Id,
            ExecutionId = DemoExecutionLogId,
            ExerciseId = SquatExerciseId,
            SetNumber = 2,
            TargetReps = 10,
            ActualReps = 9,
            WeightKg = 40,
            Rir = 1,
            RestTakenSeconds = 100,
            FormScore = 85,
            Completed = true,
        },
        new ExerciseSetLog
        {
            Id = DemoSetLog3Id,
            ExecutionId = DemoExecutionLogId,
            ExerciseId = SquatExerciseId,
            SetNumber = 3,
            TargetReps = 10,
            ActualReps = 8,
            WeightKg = 40,
            Rir = 0,
            RestTakenSeconds = 105,
            FormScore = 82,
            Completed = true,
        },
    ];

    /// <summary>Idempotent Mongo seed (run once at Roadmap.API startup).</summary>
    public static class RoadmapMongoSeeder
    {
        public static async Task SeedAsync(IMongoDatabase database, CancellationToken cancellationToken = default)
        {
            var utcNow = DateTimeOffset.UtcNow;

            await SeedCollectionAsync(
                database.GetCollection<PersonalizedRoadmap>("PersonalizedRoadmaps"),
                GetPersonalizedRoadmaps(utcNow),
                cancellationToken);

            await SeedCollectionAsync(
                database.GetCollection<RecoveryProfile>("RecoveryProfiles"),
                GetRecoveryProfiles(),
                cancellationToken);

            await SeedCollectionAsync(
                database.GetCollection<UserCustomWorkout>("UserCustomWorkouts"),
                GetUserCustomWorkouts(),
                cancellationToken);

            await SeedCollectionAsync(
                database.GetCollection<RoadmapSession>("RoadmapSessions"),
                GetRoadmapSessions(utcNow),
                cancellationToken);

            await SeedCollectionAsync(
                database.GetCollection<ScheduledWorkout>("ScheduledWorkouts"),
                GetScheduledWorkouts(utcNow),
                cancellationToken);

            await SeedCollectionAsync(
                database.GetCollection<WorkoutExecutionLog>("WorkoutExecutionLogs"),
                GetWorkoutExecutionLogs(utcNow),
                cancellationToken);

            await SeedCollectionAsync(
                database.GetCollection<ExerciseSetLog>("ExerciseSetLogs"),
                GetExerciseSetLogs(),
                cancellationToken);
        }

        private static async Task SeedCollectionAsync<T>(
            IMongoCollection<T> collection,
            IReadOnlyList<T> seeds,
            CancellationToken cancellationToken) where T : BaseMongoEntity
        {
            if (seeds.Count == 0)
                return;

            var ids = seeds.Select(s => s.Id).ToList();
            var existingIds = await collection
                .Find(Builders<T>.Filter.In(x => x.Id, ids))
                .Project(x => x.Id)
                .ToListAsync(cancellationToken);

            var toInsert = seeds.Where(s => !existingIds.Contains(s.Id)).ToList();
            if (toInsert.Count == 0)
                return;

            var now = DateTimeOffset.UtcNow;
            foreach (var entity in toInsert)
            {
                entity.CreatedAt = now;
                entity.UpdatedAt = now;
            }

            await collection.InsertManyAsync(toInsert, cancellationToken: cancellationToken);
        }
    }
}
