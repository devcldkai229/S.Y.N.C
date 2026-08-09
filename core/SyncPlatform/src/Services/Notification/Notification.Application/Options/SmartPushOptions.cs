namespace Notification.Application.Options;

public class SmartPushOptions
{
    public const string SectionName = "SmartPush";

    public bool Enabled { get; set; }
    public int ScanIntervalSeconds { get; set; } = 45;
    public int MaxPerDay { get; set; } = 2;
    public int MinGapHours { get; set; } = 5;
    public string WindowStartLocal { get; set; } = "06:00";
    public string WindowEndLocal { get; set; } = "20:00";
    public int JitterMinutes { get; set; } = 12;
    public string Model { get; set; } = "gpt-4o-mini";
    public Dictionary<string, int> TriggerCooldownDays { get; set; } = new(StringComparer.OrdinalIgnoreCase)
    {
        ["StreakProtection"] = 1,
        ["GentleCheckIn"] = 3,
        ["ProgressCelebrate"] = 1,
        ["WeighInReminder"] = 3,
    };
    public int GenerationCacheTtlMinutes { get; set; } = 240;
    public int ClaimBatchSize { get; set; } = 200;
    public bool UseAiGeneration { get; set; } = true;
    public TimeSpan NightlyRecomputeAtLocal { get; set; } = new(0, 15, 0); // 00:15
}
