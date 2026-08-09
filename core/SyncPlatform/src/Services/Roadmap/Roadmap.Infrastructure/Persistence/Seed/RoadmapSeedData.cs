using Libs.Shared.Enums;
using Libs.Shared.Seed;
using Microsoft.Extensions.Configuration;
using MongoDB.Bson;
using MongoDB.Driver;
using Roadmap.Domain.Models;

namespace Roadmap.Infrastructure.Persistence.Seed;

public static class RoadmapSeedData
{
    // ── Internal types ───────────────────────────────────────────────────────
    enum Exp { Beginner, Intermediate, Advanced }

    sealed record UserDef(
        int Nn, string RoadmapName, string Goal, string Phase, int Weeks,
        RoadmapStatus Status,
        decimal CurW, decimal TgtW, decimal CurBf, decimal TgtBf,
        bool AiInt, bool AiRes, bool AiDel,
        string Split, int Sessions, string Time,
        int RecScore, int Fatigue, int Soreness, int Cns,
        string Intensity, int WorkoutMin, Exp Experience);

    sealed record BlockTpl(string Code, int Sets, int Reps, decimal BaseW, int Rest, string Tempo = "3010");

    // ── 20 user seed definitions (Nn 02–21; User01 is empty/onboarding) ──────
    static readonly UserDef[] Users =
    [
        new(02,"Tăng cơ nền tảng 12 tuần","BuildMuscle",   "Progression",12,RoadmapStatus.Active, 74,80,18,14,true, true, true, "upper_lower",      7,"18:00",72,35,40,30,"Moderate",55,Exp.Intermediate),
        new(03,"Giảm mỡ khởi động",        "LoseFat",       "Foundation", 12,RoadmapStatus.Active, 62,55,32,26,true, true, true, "fullbody",          6,"20:00",68,55,60,45,"Light",   35,Exp.Beginner),
        new(04,"Recomp nâng cao",           "Recomposition", "Peak",       16,RoadmapStatus.Active, 82,80,16,11,true, false,true, "upper_lower_pull",  9,"06:30",80,25,30,20,"High",    70,Exp.Advanced),
        new(05,"Khỏe mỗi ngày",             "GeneralHealth", "Foundation",  8,RoadmapStatus.Active, 58,57,27,24,true, true, true, "fullbody",          6,"19:00",70,40,45,35,"Light",   30,Exp.Beginner),
        new(06,"Chạy bền 10K",              "ImproveEndurance","Progression",12,RoadmapStatus.Active,68,66,15,12,true, true, true, "endurance",         7,"06:00",60,60,65,50,"Moderate",60,Exp.Intermediate),
        new(07,"Đốt mỡ 8 tuần",             "LoseFat",       "Progression",  8,RoadmapStatus.Active, 66,58,30,24,true, true, true, "upper_lower",       7,"18:30",74,35,40,30,"Moderate",50,Exp.Intermediate),
        new(08,"Khối cơ tối đa",            "BuildMuscle",   "Peak",        16,RoadmapStatus.Active, 90,92,14,10,true, false,true, "upper_lower_pull",  9,"16:30",66,65,70,55,"High",    75,Exp.Advanced),
        new(09,"Giữ dáng bền vững",         "Maintain",      "Progression", 12,RoadmapStatus.Active, 72,72,20,18,true, true, true, "upper_lower",       7,"19:00",75,30,35,25,"Moderate",50,Exp.Intermediate),
        new(10,"Săn chắc toàn thân",        "Recomposition", "Progression", 12,RoadmapStatus.Active, 63,61,26,22,true, true, true, "upper_lower",       7,"19:00",73,35,40,30,"Moderate",55,Exp.Intermediate),
        new(11,"Giảm cân người mới",        "LoseFat",       "Foundation",  12,RoadmapStatus.Paused, 85,75,28,20,true, true, true, "fullbody",          6,"20:00",66,55,60,50,"Light",   30,Exp.Beginner),
        new(12,"Glute & thân dưới",         "BuildMuscle",   "Progression", 12,RoadmapStatus.Active, 57,60,24,22,true, true, true, "upper_lower",       7,"17:30",70,40,45,35,"Moderate",55,Exp.Intermediate),
        new(13,"Vận động văn phòng",        "GeneralHealth", "Foundation",   8,RoadmapStatus.Active, 78,74,24,19,true, true, true, "fullbody",          6,"21:00",64,50,55,45,"Light",   35,Exp.Beginner),
        new(14,"Bền bỉ & dẻo dai",          "ImproveEndurance","Progression",12,RoadmapStatus.Active, 60,59,25,22,true, true, true, "endurance",         7,"06:30",76,30,35,25,"Moderate",60,Exp.Intermediate),
        new(15,"Sức mạnh tối đa",           "BuildMuscle",   "Peak",        16,RoadmapStatus.Active, 88,90,17,13,true, false,false,"upper_lower_pull",  9,"16:00",62,70,75,60,"High",    80,Exp.Advanced),
        new(16,"Giảm mỡ an toàn (lưng)",   "LoseFat",       "Foundation",  12,RoadmapStatus.Active, 64,57,33,27,true, true, true, "fullbody",          6,"09:00",78,30,35,25,"Light",   30,Exp.Beginner),
        new(17,"Tái cấu trúc cơ thể",       "Recomposition", "Progression", 12,RoadmapStatus.Active, 79,77,21,16,true, true, true, "upper_lower",       7,"18:00",72,35,40,30,"Moderate",55,Exp.Intermediate),
        new(18,"Khởi động thể lực",         "GeneralHealth", "Foundation",   8,RoadmapStatus.Active, 55,56,23,21,true, true, true, "fullbody",          6,"19:30",72,40,45,35,"Light",   35,Exp.Beginner),
        new(19,"Marathon sub-4",            "ImproveEndurance","Peak",       16,RoadmapStatus.Active, 65,64,13,11,true, true, true, "endurance",         8,"05:30",58,65,70,55,"Moderate",75,Exp.Advanced),
        new(20,"Duy trì & tinh chỉnh",      "Maintain",      "Progression", 12,RoadmapStatus.Active, 59,58,24,21,true, true, true, "upper_lower",       7,"07:00",77,30,35,25,"Moderate",55,Exp.Intermediate),
        new(21,"Sức mạnh nền tảng",         "Maintain",      "Progression", 12,RoadmapStatus.Active, 80,80,16,14,true, false,true, "upper_lower",       7,"17:00",75,35,40,30,"High",    60,Exp.Intermediate),
    ];

    // ── Session block templates (ExerciseCodes resolved at seed time) ────────

    static readonly BlockTpl[] FullBodyA =
    [
        new("Mountain_Climbers",                 3, 30,  0m, 30, "fast"),
        new("Pushups",                           3, 12,  0m, 60, "2010"),
        new("Barbell_Lunge",                     3, 10, 30m, 75),
        new("Plank",                             3, 30,  0m, 45, "static"),
    ];

    static readonly BlockTpl[] FullBodyB =
    [
        new("Mountain_Climbers",                 3, 30,  0m, 30, "fast"),
        new("Barbell_Squat",                     3, 12, 60m, 75),
        new("Pushups",                           3, 10,  0m, 60, "2010"),
        new("Ab_Crunch_Machine",                 3, 15, 25m, 45, "controlled"),
    ];

    static readonly BlockTpl[] UpperBlocks =
    [
        new("Barbell_Bench_Press_-_Medium_Grip", 4,  8, 60m, 90),
        new("Bent_Over_Barbell_Row",             4, 10, 55m, 90),
        new("Barbell_Shoulder_Press",            3, 10, 40m, 75),
        new("Barbell_Curl",                      3, 12, 25m, 60, "2010"),
        new("Plank",                             3, 45,  0m, 45, "static"),
    ];

    static readonly BlockTpl[] LowerBlocks =
    [
        new("Barbell_Full_Squat",                4,  8, 70m, 120),
        new("Barbell_Hip_Thrust",                4, 12, 60m,  90),
        new("Barbell_Walking_Lunge",             3, 12, 40m,  75),
        new("Ab_Crunch_Machine",                 3, 15, 25m,  45, "controlled"),
    ];

    static readonly BlockTpl[] PullBlocks =
    [
        new("Pullups",                           4,  6,  0m, 90),
        new("Wide-Grip_Lat_Pulldown",            4, 10, 50m, 90),
        new("Bent_Over_Two-Dumbbell_Row",        3, 12, 25m, 75),
        new("Alternate_Hammer_Curl",             3, 12, 20m, 60, "2010"),
    ];

    static readonly BlockTpl[] EnduranceBlocks =
    [
        new("Burpee",            4, 12,  0m, 60, "fast"),
        new("Mountain_Climbers", 4, 40,  0m, 45, "fast"),
        new("Plank",             3, 45,  0m, 45, "static"),
    ];

    static readonly BlockTpl[] EnduranceStrBlocks =
    [
        new("Pushups",           3, 12,  0m, 60, "2010"),
        new("Barbell_Squat",     3, 12, 60m, 75),
        new("Plank",             3, 45,  0m, 45, "static"),
    ];

    // ── Session day offsets from today (negative = past, 0 = today, + = future)
    // Index = session count (6–9)
    static readonly int[][] DayOffsets =
    [
        [], [], [], [], [], [],
        [-14, -11,  -7, -3, -1,  4],           // 6
        [-14, -11,  -7, -4, -1,  2,  5],       // 7
        [-14, -12,  -8, -5, -2,  0,  3,  6],   // 8
        [-14, -12,  -9, -7, -5, -3, -1,  3, 7], // 9
    ];

    // User11 (Paused) uses past-only offsets
    static readonly int[] PausedOffsets = [-14, -10, -7, -5, -3, -2];

    // ── Exercise code fallback groups ────────────────────────────────────────
    static readonly Dictionary<string, string[]> Fallbacks = new()
    {
        ["Pushups"]                           = ["Barbell_Bench_Press_-_Medium_Grip", "Dumbbell_Bench_Press", "Bench_Dips"],
        ["Barbell_Bench_Press_-_Medium_Grip"] = ["Pushups", "Dumbbell_Bench_Press"],
        ["Dumbbell_Bench_Press"]              = ["Barbell_Bench_Press_-_Medium_Grip", "Pushups"],
        ["Bench_Dips"]                        = ["Pushups", "Barbell_Bench_Press_-_Medium_Grip"],
        ["Barbell_Full_Squat"]                = ["Barbell_Squat", "Barbell_Lunge"],
        ["Barbell_Squat"]                     = ["Barbell_Full_Squat", "Barbell_Lunge"],
        ["Barbell_Lunge"]                     = ["Barbell_Full_Squat", "Barbell_Walking_Lunge"],
        ["Barbell_Walking_Lunge"]             = ["Barbell_Lunge", "Barbell_Full_Squat"],
        ["Barbell_Hip_Thrust"]                = ["Barbell_Full_Squat", "Barbell_Squat"],
        ["Barbell_Deadlift"]                  = ["Barbell_Full_Squat", "Barbell_Squat"],
        ["Pullups"]                           = ["Wide-Grip_Lat_Pulldown", "Bent_Over_Barbell_Row"],
        ["Bent_Over_Barbell_Row"]             = ["Bent_Over_Two-Dumbbell_Row", "Wide-Grip_Lat_Pulldown"],
        ["Bent_Over_Two-Dumbbell_Row"]        = ["Bent_Over_Barbell_Row", "Pullups"],
        ["Wide-Grip_Lat_Pulldown"]            = ["Pullups", "Bent_Over_Barbell_Row"],
        ["Barbell_Shoulder_Press"]            = ["Side_Lateral_Raise", "Barbell_Bench_Press_-_Medium_Grip"],
        ["Side_Lateral_Raise"]               = ["Barbell_Shoulder_Press"],
        ["Barbell_Curl"]                      = ["Alternate_Hammer_Curl"],
        ["Alternate_Hammer_Curl"]             = ["Barbell_Curl"],
        ["Plank"]                             = ["Mountain_Climbers", "Pushups"],
        ["Ab_Crunch_Machine"]                 = ["Plank", "Mountain_Climbers"],
        ["Mountain_Climbers"]                 = ["Burpee", "Plank"],
        ["Burpee"]                            = ["Mountain_Climbers", "Pushups"],
    };

    // ── Stable ID helpers ────────────────────────────────────────────────────
    // PersonalizedRoadmap: f1000000-0000-4000-a000-0000000000NN
    static Guid RoadmapId(int nn) => SyncSeedUsers.ChildId("f1000000", nn);

    // RecoveryProfile: f2000000-0000-4000-a000-0000000000NN
    static Guid RecoveryId(int nn) => SyncSeedUsers.ChildId("f2000000", nn);

    // RoadmapSession: f4NN0000-0S00-4000-a000-000000000000 (NN=user, S=session 1-9)
    static Guid SessionId(int nn, int ss) =>
        Guid.Parse($"f4{nn:D2}0000-0{ss}00-4000-a000-000000000000");

    // WorkoutExecutionLog: f6NN0000-0E00-4000-a000-000000000000 (E=exec index 1-9)
    static Guid ExecLogId(int nn, int el) =>
        Guid.Parse($"f6{nn:D2}0000-0{el}00-4000-a000-000000000000");

    // ExerciseSetLog: f7000000-0000-4000-a000-NN00EEII00SS (E=exec, I=exercise, S=set)
    static Guid SetLogId(int nn, int el, int ei, int ss) =>
        Guid.Parse($"f7000000-0000-4000-a000-{nn:D2}00{el:D2}{ei:D2}{ss:D4}");

    // ── Exercise catalog resolution ──────────────────────────────────────────

    static async Task<IReadOnlyDictionary<string, (Guid Id, string NameVi)>> ResolveCodesAsync(
        IConfiguration config)
    {
        var connStr = config.GetConnectionString("ExerciseDatabase")
                   ?? config.GetConnectionString("RoadmapDatabase");

        if (string.IsNullOrEmpty(connStr))
        {
            Console.WriteLine("[RoadmapSeed] No exercise DB connection string found in configuration.");
            return new Dictionary<string, (Guid, string)>();
        }

        var dbName = config["MongoDB:ExerciseDatabaseName"] ?? "sync_exercise";
        var client = new MongoClient(connStr);
        var db     = client.GetDatabase(dbName);
        var coll   = db.GetCollection<BsonDocument>("ExerciseCatalog");

        var docs = await coll
            .Find(FilterDefinition<BsonDocument>.Empty)
            .Project(Builders<BsonDocument>.Projection.Include("ExerciseCode").Include("NameVi"))
            .ToListAsync();

        var result = new Dictionary<string, (Guid, string)>(docs.Count);
        foreach (var doc in docs)
        {
            if (!doc.Contains("ExerciseCode") || !doc.Contains("NameVi")) continue;
            var code   = doc["ExerciseCode"].AsString;
            var nameVi = doc["NameVi"].AsString;
            if (!Guid.TryParse(doc["_id"].AsString, out var id)) continue;
            result[code] = (id, nameVi);
        }

        return result;
    }

    static (Guid Id, string NameVi)? Resolve(
        string code,
        IReadOnlyDictionary<string, (Guid Id, string NameVi)> map)
    {
        if (map.TryGetValue(code, out var hit)) return hit;

        if (Fallbacks.TryGetValue(code, out var alts))
            foreach (var alt in alts)
                if (map.TryGetValue(alt, out var altHit)) return altHit;

        return null;
    }

    // ── Utility helpers ──────────────────────────────────────────────────────

    static readonly TimeSpan Utc7 = TimeSpan.FromHours(7);

    static DateTimeOffset ScheduledAt(int dayOffset, string time, DateTimeOffset utcNow)
    {
        var sp   = time.Split(':');
        int h    = int.Parse(sp[0]);
        int m    = int.Parse(sp[1]);
        var vn   = utcNow.ToOffset(Utc7);
        var date = new DateOnly(vn.Year, vn.Month, vn.Day).AddDays(dayOffset);
        return new DateTimeOffset(date.Year, date.Month, date.Day, h, m, 0, Utc7);
    }

    static decimal WeightFor(decimal baseW, Exp exp) => exp switch
    {
        Exp.Beginner     => 0m,
        Exp.Intermediate => baseW,
        Exp.Advanced     => Math.Round(baseW * 1.35m / 2.5m) * 2.5m,
        _                => 0m,
    };

    static DateTimeOffset StartDate(string phase, int weeks, DateTimeOffset now) => phase switch
    {
        "Peak"        => now.AddDays(-(weeks * 7 / 2)),
        "Progression" => now.AddDays(-(weeks * 7 / 3)),
        _             => now.AddDays(-28),
    };

    static SessionStatus DetermineStatus(int day, int si, UserDef u)
    {
        if (day >= 0) return SessionStatus.Scheduled;

        if (u.Nn == 11)
            return si % 2 == 1 ? SessionStatus.Skipped : SessionStatus.Completed;

        if (u.Experience == Exp.Beginner)
        {
            if (si == 0 || (si == 2 && day < -5))
                return SessionStatus.Skipped;
        }
        else if (u.Experience == Exp.Intermediate && si == 1 && day < -9)
        {
            return SessionStatus.Skipped;
        }

        return SessionStatus.Completed;
    }

    static (string Title, string Type, int Duration, int Energy, int Recovery, BlockTpl[] Templates)
        GetSessionMeta(string split, int si)
    {
        return split switch
        {
            "fullbody" => si % 2 == 0
                ? ("Full-body tổng hợp A", "Strength", 35, 45, 40, FullBodyA)
                : ("Full-body tổng hợp B", "Strength", 35, 48, 43, FullBodyB),

            "upper_lower" => si % 2 == 0
                ? ("Ngực-Lưng-Vai (Upper)", "Strength", 60, 65, 60, UpperBlocks)
                : ("Chân-Mông (Lower)",      "Strength", 60, 70, 65, LowerBlocks),

            "upper_lower_pull" => (si % 3) switch
            {
                0 => ("Đẩy & Vai (Upper)",  "Strength", 60, 65, 60, UpperBlocks),
                1 => ("Chân-Mông (Lower)",  "Strength", 60, 70, 65, LowerBlocks),
                _ => ("Kéo-Lưng (Pull)",   "Strength", 55, 62, 57, PullBlocks),
            },

            "endurance" => si % 3 < 2
                ? ("Cardio bền",        "Cardio",    50, 70, 65, EnduranceBlocks)
                : ("Bổ trợ sức mạnh",  "Strength",  40, 55, 50, EnduranceStrBlocks),

            _ => ("Tổng hợp", "Strength", 40, 50, 45, FullBodyA),
        };
    }

    static List<RoadmapSession.ExecutionBlock> BuildBlocks(
        BlockTpl[] templates, Exp exp,
        IReadOnlyDictionary<string, (Guid Id, string NameVi)> codeMap)
    {
        var blocks = new List<RoadmapSession.ExecutionBlock>(templates.Length);
        int order  = 1;

        foreach (var t in templates)
        {
            var resolved = Resolve(t.Code, codeMap);
            if (resolved is null) continue;

            blocks.Add(new RoadmapSession.ExecutionBlock
            {
                Order            = order++,
                ExerciseId       = resolved.Value.Id,
                ExerciseName     = resolved.Value.NameVi,
                TargetSets       = t.Sets,
                TargetReps       = t.Reps,
                TargetWeightKg   = WeightFor(t.BaseW, exp),
                RestSeconds      = t.Rest,
                Tempo            = t.Tempo,
            });
        }

        return blocks;
    }

    // ── Data builders ────────────────────────────────────────────────────────

    static IReadOnlyList<PersonalizedRoadmap> BuildRoadmaps(DateTimeOffset now) =>
        Users.Select(u =>
        {
            var start = StartDate(u.Phase, u.Weeks, now);
            return new PersonalizedRoadmap
            {
                Id                         = RoadmapId(u.Nn),
                UserId                     = SyncSeedUsers.Id(u.Nn),
                RoadmapName                = u.RoadmapName,
                FitnessGoal                = u.Goal,
                CurrentPhase               = u.Phase,
                StartDate                  = start,
                ExpectedEndDate            = start.AddDays(u.Weeks * 7),
                CurrentWeightKg            = u.CurW,
                TargetWeightKg             = u.TgtW,
                InitialFatPercentage       = u.CurBf,
                TargetFatPercentage        = u.TgtBf,
                AdaptiveAiEnabled          = true,
                AllowAiReschedule          = u.AiRes,
                AllowAiIntensityAdjustment = u.AiInt,
                AllowAiRecoveryDeload      = u.AiDel,
                RoadmapStatus              = u.Status,
            };
        }).ToList();

    static IReadOnlyList<RecoveryProfile> BuildRecoveryProfiles() =>
        Users.Select(u => new RecoveryProfile
        {
            Id                           = RecoveryId(u.Nn),
            UserId                       = SyncSeedUsers.Id(u.Nn),
            CurrentRecoveryScore         = u.RecScore,
            FatigueLevel                 = u.Fatigue,
            MuscleSorenessScore          = u.Soreness,
            CnsFatigueScore              = u.Cns,
            RecommendedTrainingIntensity = u.Intensity,
            RecommendedWorkoutDuration   = u.WorkoutMin,
        }).ToList();

    static List<RoadmapSession> BuildSessions(
        DateTimeOffset now,
        IReadOnlyDictionary<string, (Guid Id, string NameVi)> codeMap)
    {
        var sessions = new List<RoadmapSession>();

        foreach (var u in Users)
        {
            var offsets   = u.Nn == 11 ? PausedOffsets : DayOffsets[u.Sessions];
            var roadmapId = RoadmapId(u.Nn);

            for (int si = 0; si < offsets.Length; si++)
            {
                int day      = offsets[si];
                var status   = DetermineStatus(day, si, u);
                var scheduled = ScheduledAt(day, u.Time, now);

                var (title, type, duration, energy, recovery, tplBlocks) =
                    GetSessionMeta(u.Split, si);

                var blocks = BuildBlocks(tplBlocks, u.Experience, codeMap);
                if (blocks.Count == 0)
                {
                    Console.WriteLine($"[RoadmapSeed] User {u.Nn} session {si + 1}: no exercise blocks resolved — skipping session.");
                    continue;
                }

                sessions.Add(new RoadmapSession
                {
                    Id                        = SessionId(u.Nn, si + 1),
                    RoadmapId                 = roadmapId,
                    ScheduledDate             = scheduled,
                    ScheduledTime             = u.Time,
                    Timezone                  = "Asia/Ho_Chi_Minh",
                    SessionType               = type,
                    SessionTitle              = title,
                    EstimatedDurationMinutes  = duration,
                    EnergyDemandScore         = energy,
                    RecoveryRequirementScore  = recovery,
                    NotificationEnabled       = true,
                    NotificationMinutesBefore = 30,
                    AiGenerated               = true,
                    SessionStatus             = status,
                    ExecutionBlocks           = blocks,
                });
            }
        }

        return sessions;
    }

    static int FindNnForRoadmap(Guid roadmapId)
    {
        for (int nn = 2; nn <= 21; nn++)
            if (RoadmapId(nn) == roadmapId) return nn;
        return 0;
    }

    static (int Duration, int Calories, int Difficulty, int EnergyBefore, int EnergyAfter,
            int CompletionRate, string Feedback)
        CalcExecMetrics(UserDef u, RoadmapSession session, int el)
    {
        int duration      = session.EstimatedDurationMinutes - 2 + (el % 4);
        int calPerMin     = session.SessionType == "Cardio" ? 9 : 7;
        int calories      = duration * calPerMin;
        int difficulty    = u.Experience == Exp.Advanced     ? 5 + el % 4
                          : u.Experience == Exp.Intermediate ? 4 + el % 4
                          :                                    4 + el % 5;
        difficulty        = Math.Min(difficulty, 9);
        int energyBefore  = Math.Clamp(u.RecScore / 12, 3, 8);
        int energyAfter   = Math.Max(energyBefore - 2, 2);
        int completionRate = u.Experience == Exp.Advanced     ? Math.Min(100, 95 + el % 5)
                           : u.Experience == Exp.Intermediate ? Math.Min(100, 82 + el % 14)
                           :                                    Math.Min(100, 68 + el % 22);

        string feedback = session.SessionType == "Cardio"
            ? "Nhịp tim ổn định, duy trì tốt — tăng cường độ dần dần."
            : u.Experience == Exp.Advanced
            ? "Form xuất sắc, tuần sau tăng tạ 2.5 kg."
            : u.Experience == Exp.Intermediate
            ? "Buổi tập hiệu quả, tiếp tục duy trì nhịp độ."
            : "Cố gắng tốt, nhớ giữ form trước khi tăng khối lượng.";

        return (duration, calories, difficulty, energyBefore, energyAfter, completionRate, feedback);
    }

    static (List<WorkoutExecutionLog> ExecLogs, List<ExerciseSetLog> SetLogs) BuildLogs(
        DateTimeOffset now, List<RoadmapSession> sessions)
    {
        var execLogs = new List<WorkoutExecutionLog>();
        var setLogs  = new List<ExerciseSetLog>();
        var countByNn = new int[22];

        var completed = sessions
            .Where(s => s.SessionStatus == SessionStatus.Completed)
            .OrderBy(s => s.ScheduledDate)
            .ToList();

        foreach (var session in completed)
        {
            int nn = FindNnForRoadmap(session.RoadmapId);
            if (nn == 0) continue;

            countByNn[nn]++;
            int el    = countByNn[nn];
            var u     = Users.First(x => x.Nn == nn);
            var logId = ExecLogId(nn, el);

            var (duration, calories, difficulty, energyBefore, energyAfter, completionRate, feedback) =
                CalcExecMetrics(u, session, el);

            execLogs.Add(new WorkoutExecutionLog
            {
                Id                    = logId,
                UserId                = SyncSeedUsers.Id(nn),
                SessionId             = session.Id,
                StartedAt             = session.ScheduledDate,
                CompletedAt           = session.ScheduledDate.AddMinutes(duration),
                ActualDurationMinutes = duration,
                PerceivedDifficulty   = difficulty,
                EnergyLevelBefore     = energyBefore,
                EnergyLevelAfter      = energyAfter,
                CaloriesBurned        = calories,
                CompletionRate        = completionRate,
                AiCoachFeedback       = feedback,
                SkippedExercises      = [],
            });

            for (int ei = 0; ei < session.ExecutionBlocks.Count; ei++)
            {
                var block = session.ExecutionBlocks[ei];
                for (int ss = 1; ss <= block.TargetSets; ss++)
                {
                    bool isLastSet = ss == block.TargetSets;
                    setLogs.Add(new ExerciseSetLog
                    {
                        Id               = SetLogId(nn, el, ei + 1, ss),
                        ExecutionId      = logId,
                        ExerciseId       = block.ExerciseId,
                        SetNumber        = ss,
                        TargetReps       = block.TargetReps,
                        ActualReps       = block.TargetReps - (isLastSet ? 2 : 0),
                        WeightKg         = block.TargetWeightKg,
                        Rir              = block.TargetSets - ss + 1,
                        RestTakenSeconds = block.RestSeconds + 5,
                        FormScore        = Math.Max(60, 90 - (ss - 1) * 3 - (u.Experience == Exp.Beginner ? 5 : 0)),
                        Completed        = true,
                    });
                }
            }
        }

        return (execLogs, setLogs);
    }

    // ── Seeder entry point ───────────────────────────────────────────────────

    public static class RoadmapMongoSeeder
    {
        public static async Task SeedAsync(
            IMongoDatabase roadmapDb,
            IConfiguration configuration,
            CancellationToken ct = default)
        {
            // 1. Resolve ExerciseCodes from Exercise catalog (sync_exercise DB)
            var codeMap = await ResolveCodesAsync(configuration);
            if (codeMap.Count == 0)
            {
                Console.WriteLine("[RoadmapSeed] ExerciseCatalog unreachable or empty — aborting roadmap seed. Run 'import-free-exercise-db' first.");
                return;
            }

            Console.WriteLine($"[RoadmapSeed] Resolved {codeMap.Count} exercise catalog entries.");

            var now = DateTimeOffset.UtcNow;

            // 2. Build all seed data
            var roadmaps  = BuildRoadmaps(now);
            var recoveries = BuildRecoveryProfiles();
            var sessions  = BuildSessions(now, codeMap);
            var (execLogs, setLogs) = BuildLogs(now, sessions);

            // 3. Idempotent insert
            await SeedCollectionAsync(roadmapDb.GetCollection<PersonalizedRoadmap>("PersonalizedRoadmaps"), roadmaps, ct);
            await SeedCollectionAsync(roadmapDb.GetCollection<RecoveryProfile>("RecoveryProfiles"), recoveries, ct);
            await SeedCollectionAsync(roadmapDb.GetCollection<RoadmapSession>("RoadmapSessions"), sessions, ct);
            await SeedCollectionAsync(roadmapDb.GetCollection<WorkoutExecutionLog>("WorkoutExecutionLogs"), execLogs, ct);
            await SeedCollectionAsync(roadmapDb.GetCollection<ExerciseSetLog>("ExerciseSetLogs"), setLogs, ct);

            Console.WriteLine($"[RoadmapSeed] Done — Roadmaps: {roadmaps.Count}, Sessions: {sessions.Count}, ExecLogs: {execLogs.Count}, SetLogs: {setLogs.Count}");
        }

        static async Task SeedCollectionAsync<T>(
            IMongoCollection<T> collection,
            IReadOnlyList<T> seeds,
            CancellationToken ct) where T : BaseMongoEntity
        {
            if (seeds.Count == 0) return;

            var ids = seeds.Select(s => s.Id).ToList();
            var existingIds = await collection
                .Find(Builders<T>.Filter.In(x => x.Id, ids))
                .Project(x => x.Id)
                .ToListAsync(ct);

            var toInsert = seeds.Where(s => !existingIds.Contains(s.Id)).ToList();
            if (toInsert.Count == 0) return;

            var now = DateTimeOffset.UtcNow;
            foreach (var e in toInsert) { e.CreatedAt = now; e.UpdatedAt = now; }

            await collection.InsertManyAsync(toInsert, cancellationToken: ct);
            Console.WriteLine($"[RoadmapSeed] Inserted {toInsert.Count} into {collection.CollectionNamespace.CollectionName}.");
        }
    }
}
