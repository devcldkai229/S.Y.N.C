namespace Iam.Application.DTOs;

public sealed record LogActivityResponse(
    int CurrentStreak,
    int LongestStreak,
    bool AlreadyLoggedToday,
    IReadOnlyList<string> NewlyUnlockedAchievements);
