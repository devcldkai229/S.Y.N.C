namespace Iam.Domain.Enums;

/// <summary>
/// Hệ số hoạt động hằng ngày — đầu vào TDEE/BMR và workload gợi ý.
/// </summary>
public enum ActivityLevel
{
    None = 0,
    Sedentary = 1,
    LightlyActive = 2,
    ModeratelyActive = 3,
    VeryActive = 4,
    Athlete = 5
}
