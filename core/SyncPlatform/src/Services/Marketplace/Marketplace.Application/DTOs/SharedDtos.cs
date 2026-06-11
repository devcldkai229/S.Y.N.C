using Libs.Shared.Common;

namespace Marketplace.Application.DTOs;

public class LocationDto
{
    public double Latitude { get; set; }

    public double Longitude { get; set; }
}

public class OperatingHourDto
{
    public int DayOfWeek { get; set; }

    public string OpenTime { get; set; } = string.Empty;

    public string CloseTime { get; set; } = string.Empty;

    public bool IsClosed { get; set; }
}

public class AuthorSnapshotDto
{
    public string FullName { get; set; } = string.Empty;

    public string? AvatarUrl { get; set; }
}

public class NutritionSnapshotDto
{
    public int Calories { get; set; }

    public decimal ProteinGram { get; set; }

    public decimal CarbGram { get; set; }

    public decimal FatGram { get; set; }

    public string? ServingDescription { get; set; }

    public static NutritionSnapshotDto FromValueObject(NutritionSnapshot snapshot) => new()
    {
        Calories = snapshot.Calories,
        ProteinGram = snapshot.ProteinGram,
        CarbGram = snapshot.CarbGram,
        FatGram = snapshot.FatGram,
        ServingDescription = snapshot.ServingDescription,
    };

    public NutritionSnapshot ToValueObject() => new()
    {
        Calories = Calories,
        ProteinGram = ProteinGram,
        CarbGram = CarbGram,
        FatGram = FatGram,
        ServingDescription = ServingDescription,
    };
}
